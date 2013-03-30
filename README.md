Puppet Module to manage the Zimbra Mail Server
==============================================
##Description

A Puppet module to manage the Zimbra Collaboration Suite.
As of this moment the module is able to manage users and mailing lists.
To improve performance,  when prefetching the state of resources, the provider uses ldapsearch. 
When  making configuration changes however, the zmprov utility is used to ensure date consistency-- 
at the expense of performance.


##Sample usage

puppet resource zimbra_user domain=mydomain.com

    zimbra_user {
        'rocky':
            ensure       => present,
            domain       => 'mydomain.com',
            aliases      => ['mordor@mydomain.com', 'marciano@mydomain.com'],
            user_name    =>  'Rocky Marciano',
            pwd          => 'Tjnnh)9',
            mailbox_size => '1G';
     }

    zimbra_list {
        'list':
            ensure => present,
            aliases => ['floyd@mydomain.com','pink@mydomain.com'],
            members => ['rocky@mydomain.com','saruman@mydomain.com'],
            domain => 'mydomain.com',
    }

##TODO

Calendar and sharing support.
Domain management.

##License

  Copyright 2013 Evelio Vila

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
	   limitations under the License.

