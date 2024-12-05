curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list
sudo apt-get update
sudo apt-get install -y mssql-server
sudo ACCEPT_EULA=Y MSSQL_SA_PASSWORD='Password1234!' MSSQL_PID=Developer MSSQL_MEMORY_LIMIT_MB=2048 MSSQL_TCP_PORT=1433 /opt/mssql/bin/mssql-conf -n setup
systemctl status mssql-server --no-pager
