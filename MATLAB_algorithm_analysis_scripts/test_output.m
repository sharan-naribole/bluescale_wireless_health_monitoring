clc;clear;
% MySql host, username and password
hostname = 'localhost';
username = '';
password = '';
% List of MySql commands
query{1} = 'USE bmdtest_it_db';
query{2} = 'SELECT id,username,password FROM tabella WHERE 1=1';
% The file php_output.php has to be available at the remote server
url      = 'http://www.myserver.com/php_output.php';

[out]    = mysql_output(hostname,username,password,query,url);
% Now out is a cell with the required values.
% For example if the table "tabella" is:
% id     username  password
% 1      jack      ross
% 2      paul      secret
% 3      mike      hall
%
% out has the following form:
% out{1} = '1'
% out{2} = 'jack'
% out{3} = 'ross'
% out{4} = '2'
% out{5} = 'paul'
% out{6} = 'secret'
% out{7} = '3'
% out{8} = 'mike'
% out{9} = 'hall'
% supposing that the MySql query is 'SELECT id,username,password FROM tabella WHERE 1=1' 