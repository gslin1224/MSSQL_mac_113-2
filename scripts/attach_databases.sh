#!/bin/bash
# 等待 SQL Server 完全啟動（根據需要可調整等待時間）
echo "等待 SQL Server 啟動中..."
sleep 30

DATA_DIR="/var/opt/mssql/data"
SERVER="mssql"
USER="SA"
PASSWORD="p4ssw0rd!"

# 掃描資料夾內所有 MDF 檔案
for MDF in $(find "$DATA_DIR" -maxdepth 1 -type f -name "*.mdf"); do
    DBNAME=$(basename "$MDF" .mdf)
    LDF="${DATA_DIR}/${DBNAME}_log.ldf"
    
    echo "檢查資料庫 '$DBNAME' 是否已存在..."
    # 查詢是否已附加此資料庫
    EXISTS=$(/opt/mssql-tools/bin/sqlcmd -S $SERVER -U $USER -P $PASSWORD -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name='$DBNAME';" -h -1 | tr -d '[:space:]')
    
    if [ "$EXISTS" -eq 0 ]; then
        if [ -f "$LDF" ]; then
            echo "附加資料庫 '$DBNAME'（包含 MDF 與 LDF）..."
            /opt/mssql-tools/bin/sqlcmd -S $SERVER -U $USER -P $PASSWORD -Q "CREATE DATABASE [$DBNAME] ON (FILENAME = '$MDF'), (FILENAME = '$LDF') FOR ATTACH;"
        else
            echo "附加資料庫 '$DBNAME'（僅 MDF，重建日誌）..."
            /opt/mssql-tools/bin/sqlcmd -S $SERVER -U $USER -P $PASSWORD -Q "CREATE DATABASE [$DBNAME] ON (FILENAME = '$MDF') FOR ATTACH_REBUILD_LOG;"
        fi
    else
        echo "資料庫 '$DBNAME' 已存在，略過。"
    fi
done

echo "附加 MDF 檔案作業完成。"

