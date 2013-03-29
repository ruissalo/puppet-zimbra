Puppet::Type.type(:zimbra_user).provide(:zmprov) do

    desc "Manage users for Zimbra Collaboration Suite"

    confine :operatingsystem => [:Ubuntu,:Debian]
    confine :true => begin
        File.exists?('/opt/zimbra/bin/zmprov') && File.exists?('/opt/zimbra/bin/ldapsearch')
    end
    defaultfor :operatingsystem => [:Ubuntu]

    commands :zmprov => '/opt/zimbra/bin/zmprov',
             :zmmailbox => '/opt/zimbra/bin/zmmailbox',
             :ldapsearch => '/opt/zimbra/bin/ldapsearch',
             :zmlocalconfig => '/opt/zimbra/bin/zmlocalconfig'
            
    require 'socket'
    @host_name=Socket.gethostbyname(Socket.gethostname.to_s)[0]

#    mk_resource_methods

    def self.instances
        

        # Getting ldap password
        ldap_pass = zmlocalconfig('-s','zimbra_ldap_password').gsub('zimbra_ldap_password = ','').chomp("\n")

        # Configuring ldap filter for users
        ufilter = "(&(objectClass=inetOrgPerson)(objectClass=zimbraAccount))"

        # here we get all users
        raw = ldapsearch('-LLL','-H',"ldap://#{@host_name}:389",'-D','uid=zimbra,cn=admins,cn=zimbra','-x','-w',ldap_pass,ufilter)

        # zimbraCOS
        cos_filter='objectClass=zimbraCOS'
        quotas=Hash.new
        raw_COS = ldapsearch('-LLL','-H',"ldap://#{@host_name}:389",'-D','uid=zimbra,cn=admins,cn=zimbra','-x','-w',ldap_pass,cos_filter).split("\n\n")
        raw_COS.each do |v|
            if v.include?('dn: cn=default,cn=cos,cn=zimbra')
                cos_id="default"
            else    
                cos_id= v.grep(/zimbraId: .*\n/).to_s.gsub('zimbraId: ','').chomp
            end
            quota= v.grep(/zimbraMailQuota: .*\n/).to_s.gsub('zimbraMailQuota: ','').chomp
            quotas[cos_id]=quota
        end
        #############
        
        raw_users=raw.split("\n\n")
        raw_users.compact.map  { |i| 
            # getting uid
            name = i.grep(/uid: /)[0].gsub('uid: ','').chomp

            # getting displayName
            if i.include?('displayName: ')
                displayName = i.grep(/displayName: /)[0].gsub('displayName: ','').chomp
            else
                displayName = String.new
            end    
            # getting aliases for each user
            raw_aliases=i.grep(/zimbraMailAlias: /)
            unless raw_aliases.empty?
                aliases= raw_aliases.collect { |x| x.gsub('zimbraMailAlias: ','').gsub("\n",'')}
            else
                aliases= Array.new
            end

            # getting mailBox quota

            if i.grep(/zimbraMailQuota: /).empty? and i.grep(/zimbraCOSId: /).empty?
                quota = quotas['default']
            elsif  i.grep(/zimbraMailQuota: /).any?
                quota = i.grep(/zimbraMailQuota: /).to_s.gsub('zimbraMailQuota: ','').chomp
            elsif i.grep(/zimbraCOSId: /).any?
                zimbraid = i.grep(/zimbraCOSId: /).to_s.gsub('zimbraCOSId: ','').chomp
                quota=quotas[zimbraid]
            end

            new(:name => name, 
                :ensure => :present, 
                :user_name => displayName, 
                :aliases => aliases,
                :mailbox_size => quota)
        }
    end

    def self.prefetch(resources)
        users = instances
        resources.keys.each do |name|
            if provider = users.find{ |usr| usr.name == name }
                resources[name].provider = provider
            end
        end
    end

    def exists?
        @property_hash[:ensure] == :present
	end

    def create
        # Create user mailbox
        #
        #
        options= Array.new
        (options << 'zimbraMailHost' << resource[:location]) if resource[:location]
        (options << 'zimbraMailQuota' << resource[:mailbox_size]) if resource[:mailbox_size]
        (options << 'displayName' <<  resource[:user_name]) if resource[:user_name]

        zmprov('ca',resource[:mailbox]+'@'+resource[:domain],resource[:pwd],options)
        # Add aliases
        unless resource[:aliases].nil?
            resource[:aliases].flatten.each { |element|
                zmprov('aaa',resource[:mailbox]+'@'+resource[:domain],element)
            }
        end
    end

    def destroy
        zmprov('da',resource[:mailbox]+'@'+resource[:domain])
    end

    def mailbox_size
        @property_hash[:mailbox_size]
    end

    def aliases
        @property_hash[:aliases]
    end


    def mailbox_size=(value)
        zmprov('ma',resource[:mailbox]+'@'+resource[:domain], 'zimbraMailQuota', resource[:mailbox_size])
    end

    def aliases=(value)
        STDERR.puts resource[:aliases].inspect
        remove_diff = @property_hash[:aliases] - resource[:aliases].flatten

        if remove_diff.any?
            remove_diff.each { |val|
                zmprov('raa',resource[:mailbox]+'@'+resource[:domain],val)
            }
        end
        add_diff = resource[:aliases].flatten - @property_hash[:aliases]
        if add_diff.any?
            add_diff.each { |val|
                zmprov('aaa',resource[:mailbox]+'@'+resource[:domain],val)
            }
        end
    end
end
