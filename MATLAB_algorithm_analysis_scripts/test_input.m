clc;clear;
% MySql host, username and password
hostname = 'localhost';
username = '';
password = '';
% List of MySql commands
query{1} = 'USE bmdtest_it_db';
query{2} = 'INSERT INTO tabella (id, username, password) VALUES (''78'', ''rosa'', ''di pietro'');';
%query{2} = 'DELETE FROM `tabella` WHERE `id` = ''57'' LIMIT 1';
% The file php_input.php has to be available at the remote server
url      = 'http://www.myserver.com/php_input.php';

[out]    = mysql_input(hostname,username,password,query,url);
% Now all MySql commands have been executed.