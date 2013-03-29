Puppet::Type.type(:zimbra_list).provide(:zmprov) do

    desc "Manages mailing lists for Zimbra Collaboration Suite"

    confine :operatingsystem => [:Ubuntu,:Debian]
    confine :true => begin
        File.exists?('/opt/zimbra/bin/zmprov') && File.exists?('/opt/zimbra/bin/ldapsearch')
    end
    defaultfor :operatingsystem => [:Ubuntu]

    commands :zmprov => '/opt/zimbra/bin/zmprov',
             :zmmailbox => '/opt/zimbra/bin/zmmailbox',
             :ldapsearch => '/opt/zimbra/bin/ldapsearch',
             :zmlocalconfig => '/opt/zimbra/bin/zmlocalconfig'


    mk_resource_methods

    require 'socket' 
    
    def self.instances
        host_name=Socket.gethostbyname(Socket.gethostname.to_s)[0]
        # Getting ldap password
        ldap_pass = zmlocalconfig('-s','zimbra_ldap_password').gsub('zimbra_ldap_password = ','').chomp("\n")

        # Configuring ldap filter for users
        lfilter = 'objectClass=zimbraDistributionList'

        # here we get all users
        raw = ldapsearch('-LLL','-H',"ldap://#{host_name}:389",'-D','uid=zimbra,cn=admins,cn=zimbra','-x','-w',ldap_pass,lfilter)

        raw_lists=raw.split("\n\n")
        raw_lists.compact.map  { |i| 
            # getting uid
            name = i.grep(/uid: /)[0].gsub('uid: ','').chomp

            # getting displayName
            if i.include?('displayName: ')
                displayName = i.grep(/displayName: /)[0].gsub('displayName: ','').chomp
            else
                displayName = String.new
            end    
            # getting aliases
            raw_aliases=i.grep(/zimbraMailAlias: /)
            unless raw_aliases.empty?
                aliases= raw_aliases.collect { |x| x.gsub('zimbraMailAlias: ','').chomp}
                aliases.delete_at(0)
            else
                aliases= Array.new
            end
            # getting members

            raw_members=i.grep(/zimbraMailForwardingAddress: /)
            unless raw_aliases.empty?
                members= raw_members.collect { |x| x.gsub('zimbraMailForwardingAddress: ','').chomp}
            else
                members= Array.new
            end



            new(:name => name, 
                :ensure => :present, 
                :display_name => displayName, 
                :members => members,
                :aliases => aliases)
        }
    end

    def self.prefetch(resources)
        lists = instances
        resources.keys.each do |name|
            if provider = lists.find{ |usr| usr.name == name }
                resources[name].provider = provider
            end
        end
    end

    def exists?
        @property_hash[:ensure] == :present
	end

    def create
        # Create list
        options = Array.new
        (options << 'displayName' << resource[:display_name]) if resource[:display_name]

        zmprov('cdl',resource[:list]+'@'+resource[:domain],options)

        # Add aliases
        unless resource[:aliases].nil?
            resource[:aliases].each { |y|
                zmprov('adla',resource[:list]+'@'+resource[:domain],y)
            }
        end
        # Add members
        unless resource[:members].nil?
            resource[:members].each { |x|
                zmprov('adlm',resource[:list]+'@'+resource[:domain],x)
            }
        end

    end

    def display_name=(value)
        zmprov('mdl',resource[:list]+'@'+resource[:domain],'displayName',resource[:display_name])
    end

    def destroy
        zmprov('ddl',resource[:list]+'@'+resource[:domain])
    end

    def aliases=(value)
        remove_diff = @property_hash[:aliases] - resource[:aliases].flatten
        if remove_diff.any?
            remove_diff.each { |val|
                zmprov('rdla',resource[:list]+'@'+resource[:domain],val)
            }
        end
        add_diff = resource[:aliases].flatten - @property_hash[:aliases]
        if add_diff.any?
            add_diff.each { |val|
                zmprov('adla',resource[:list]+'@'+resource[:domain],val)
            }
        end
    end

    def members=(value)
        remove_diff = @property_hash[:members] - resource[:members].flatten

        if remove_diff.any?
            remove_diff.each { |val|
                zmprov('rdlm',resource[:list]+'@'+resource[:domain],val)
            }
        end
        add_diff = resource[:members].flatten - @property_hash[:members]
        if add_diff.any?
            add_diff.each { |val|
                zmprov('adlm',resource[:list]+'@'+resource[:domain],val)
            }
        end
    end

end
