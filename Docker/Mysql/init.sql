-- Grant remote access to user
GRANT ALL PRIVILEGES ON db1.* TO 'usr'@'%' IDENTIFIED BY '123';
FLUSH PRIVILEGES;
