Puppet::Type.newtype(:zimbra_user) do

    desc "Type to manage Zimbra users"

    ensurable

    newproperty(:aliases, :array_matching => :all) do
        desc "Mailbox aliases"
        validate do |value|
            value.each do |val|
                fail("Aliases must be fully qualified") unless val =~ /.*@.*/
            end
        end
        munge do |value|
            value
        end
    end

    newproperty(:mailbox_size) do
        desc "The size of the mailbox"
        validate do |value|
            fail("Invalid mailbox size, it should contain a number and a unit M|G") unless value =~ /\d+(M|G){1}/
        end
        munge do |value|
            if value.include? 'G'
                (value.chomp('G').to_i * 1024 * 1024 * 1024).to_s
            elsif value.include? 'M'
                (value.chomp('M').to_i * 1024 * 1024).to_s
            end
        end    
    end

    newparam(:domain) do
        desc "Account domain"
    end

    newparam(:location) do
        desc "mailbox location in the cluster"
    end

    newparam(:user_name) do
        desc "username"
    end

    newparam(:mailbox, :namevar => true) do
        desc 'Mailbox'
    end

    newparam(:pwd) do
        desc 'Mailbox password'
        defaultto 'Troutr0,'
        validate do |value|
            fail("Password not strong enough") unless value =~ /^(?=.*[A-Z])(?=.*[!@#$&,])(?=.*[0-9]).{8}$/
        end
    end

    validate do
        raise Puppet::Error, "Must specify domain parameter" unless
        @parameters.include?(:domain)
    end

end
