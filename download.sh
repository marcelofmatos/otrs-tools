# curl https://raw.githubusercontent.com/marcelofmatos/otrs-tools/main/download.sh | bash; perl scripts/ldap_connection_test.pl

curl https://raw.githubusercontent.com/marcelofmatos/otrs-tools/main/scripts/ldap_auth_check.pl      > /opt/otrs/scripts/ldap_auth_check.pl
curl https://raw.githubusercontent.com/marcelofmatos/otrs-tools/main/scripts/ldap_connection_test.pl > /opt/otrs/scripts/ldap_connection_test.pl
curl https://raw.githubusercontent.com/marcelofmatos/otrs-tools/main/scripts/ldap_search_test.pl     > /opt/otrs/scripts/ldap_search_test.pl
curl https://raw.githubusercontent.com/marcelofmatos/otrs-tools/main/scripts/ldap_groups_check.pl    > /opt/otrs/scripts/ldap_groups_check.pl
