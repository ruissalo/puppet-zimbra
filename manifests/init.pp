class zimbra {
    zimbra_user {
        'rocky':
            ensure       => present,
            domain       => 'mydomain.com',
            aliases      => ['boxer@mydomain.com', 'marciano@mydomain.com'],
            mailbox_size => '1G',
    }

    zimbra_list {
        'list':
            ensure  => present,
            aliases => ['qsdf@mydomain.com','1223@mydomain.com'],
            members => ['rocky@mydomain.com'],
            domain  => 'mydomain.com',
    }

    zimbra_list {
        'anotherlist':
            ensure       => present,
            aliases      => ['myalias@mydomain.com','mysecondalias@mydomain.com'],
            domain       => 'mydomain.com',
            display_name => 'Anohter List';
    }

}
