Puppet::Type.newtype(:zimbra_list) do

    desc "Type to manage Zimbra mailing lists"

    ensurable

    newparam(:list, :namevar => true) do
        desc "Zimbra mailing list id"
        validate do |value|
            fail("list name can't be fully qualified. Use domain param.") if value =~ /.*@.*/
        end
    end

    newproperty(:members, :array_matching => :all) do
        desc "mailing list's members"
        validate do |value|
            value.each do |val|
                fail("member addr must be fully qualified") unless val =~ /.*@.*/
            end
        end

#        munge do |value|
#            value.sort
#        end
    end

    newproperty(:display_name) do
        desc "Display Name"
    end


    newproperty(:aliases, :array_matching => :all) do
        desc "mailing list's aliases"
        validate do |value|
            value.each do |val|
                fail("Aliases must be fully qualified") unless val =~ /.*@.*/
            end
        end

#        munge do |value|
#            value.sort
#        end
    end


    newparam(:domain) do
        desc "list domain"
    end

    validate do
        raise Puppet::Error, "Must specify domain parameter" unless
        @parameters.include?(:domain)
    end

end
