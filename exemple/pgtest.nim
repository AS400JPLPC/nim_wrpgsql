import wrpgsql
import strformat

# specifique for test
import terminal

# exit for try 

type STOP = object of IOError
proc quitClean()=
  var e: ref STOP
  new(e)
  raise e
proc quitLine(ligne :int=0)=
  var e: ref STOP
  new(e)
  e.msg = fmt" ligne :{ligne}"
  raise e




var Db* : PGdb.Db
var Conn* = new(PGsql)
var TypeField* : DbType 
var Columns*:  DbColumns
var requete : string 

var DbProd* : PGdb.Db
var ConnProd* = new(PGsql)


try :

  Db = Connect("localhost","5432","CGIFCH","readonly","read","pgtest-Read")
  echo "status : ",Db.status
  echo "Database : ",GetDb(Db)
  echo "GetUser : ", GetUser(Db)
  DbProd = Connect("localhost","5432","CGIFCH","userpgm","usrpgm","pgtest-USE")



  try :
    Db.isTable("FC0CLI") :
  except NOTFOUND :
    echo "NOT FOUND :" , getCurrentExceptionMsg()
    quitLine(47)



  requete =fmt""" SELECT   *   from "FC0CLI"  WHERE "C0NCLI" = 79928;""" 
  Db.sqlQuery(Conn, requete )
  echo Conn.Rows
  echo Conn.Cols




  requete =fmt""" SELECT   *   from "FC2CLI"  order by "C2NCLI";""" 
  Db.sqlQuery(Conn, requete )
  echo Conn.Rows
  echo Conn.Cols


  echo " setFirst test eof etc..."
  Db.Begin()
  requete =fmt"SELECT * FROM tabletype order by vkey ;" 
  Db.sqlFirst(Conn, requete ,"MYcursor" )
  echo Conn.Rows
  echo Conn.Cols
  while not Conn.Eof :
    for c in 0 .. Conn.Field:
      echo "Name :",Conn.sqlName(c),"  value : ",Conn.sqlValue(Conn.Rang, c)
    echo"--"
    Db.sqlNext(Conn,"MYcursor" )
  Db.Commit()
  
  echo "pause 78 :", getch()

  echo " Back test eof etc..."
  Db.Begin()
  requete =fmt"SELECT * FROM tabletype where vkey <= 1011 order by vkey ;" 
  Db.sqlLast(Conn, requete ,"MYcursor" )
  echo Conn.Rows
  echo Conn.Cols
  while not Conn.Eof :
    for c in 0 .. Conn.Field:
      echo "Name :",Conn.sqlName(c),"  value : ",Conn.sqlValue(Conn.Rang, c)
    echo"--"
    Db.sqlPrior(Conn,"MYcursor" )
  Db.Commit()
  
  echo "pause 93 :", getch()

  echo"__LIMIT / PAGE__"
  try :
    requete =fmt"""SELECT "NBNDOS" FROM "FNBDOS"  WHERE "NBNDOS" >= 671005 ORDER BY "NBNDOS" ;""" 
    Db.sqlPage(Conn, requete , 10 )
    echo Conn.Rows
    echo Conn.Cols
    for r in 0 .. Conn.Rang:
      for c in 0 .. Conn.Field:
        echo "  value : ",Conn.sqlValue(r, c)
  except NOTFOUND :
    echo "NOT FOUND :" , getCurrentExceptionMsg()
  except ERRSQL :
    echo "ERR SQL :" , getCurrentExceptionMsg()
    quitLine(109)
  echo "pause 109 :", getch()
    
  echo "test sqllock"
  try:
    DbProd.Begin()
    requete =fmt"SELECT * FROM tabletype  WHERE vkey = 1011 ;" 
    DbProd.sqlLock(ConnProd, requete )
    echo ConnProd.Rows
    echo ConnProd.Cols
  
    echo "pause 119 :", getch()

    Db.Commit()
    clearRslt(ConnProd)
  except:
    echo getCurrentExceptionMsg()
    echo "pause 125 :", getch()
  finally: closeDb(DbProd)

  requete =fmt"SELECT * FROM tabletype  WHERE vkey = 1011 ;" 
  Db.sqlQuery(Conn, requete )
  echo Conn.Rows
  echo Conn.Cols

  echo "Name :",Conn.sqlName(Conn.Field)
  Db.sqlQueryInfo(Conn,Columns)


  for i in 0..<len(Columns) :
    echo "name :",Columns[i].name
    echo "tableName :",Columns[i].tableName
    echo "typ :",Columns[i].typ
    echo "position :",Columns[i].position
    echo "nullable :",Columns[i].nullable
    echo "maxchar :",Columns[i].maxchar
    echo "precision :",Columns[i].precision
    echo "scale :",Columns[i].scale
    echo "comment :",Columns[i].comment
    echo "---------------------------"



  for r in 0 .. Conn.Rang:
    for c in 0 .. Conn.Field:
      echo "Name :",Conn.sqlName(c), "  value : ",Conn.sqlValue(r, c) ,"   --- Type : ",Conn.sqlType(c)
  
  
  
  ## read table convertie from AS400 to PGSQL
  requete =fmt"""SELECT "NBNDOS", "C0ZNOM" FROM "FNBDOS", "FC0CLI", "FNADOS"  
  WHERE "NBNDOS" = 271049 and "NANDOS" = "NBNDOS" and "C0NCLI" = "NANCLI" ;""" 
  Db.sqlQuery(Conn, requete )
  echo Conn.Rows
  echo Conn.Cols


  for r in 0 .. Conn.Rang:
    for c in 0 .. Conn.Field:
      echo "Name :",Conn.sqlName(c), "  value : ",Conn.sqlValue(r, c)
  echo "pause 166:", getch()
  Db.sqlQueryInfo(Conn,Columns)
  echo "pause 168:", getch()
 

  for i in 0..<len(Columns) :
    echo "name :",Columns[i].name
    echo "tableName :",Columns[i].tableName
    echo "typ :",Columns[i].typ
    echo "position :",Columns[i].position
    echo "nullable :",Columns[i].nullable
    echo "maxchar :",Columns[i].maxchar
    echo "precision :",Columns[i].precision
    echo "scale :",Columns[i].scale
    echo "comment :",Columns[i].comment
    echo "---------------------------"

  #quitLine(158)



  Db.sqlColInfo("tabletype",Columns )
  echo "---------------------------"
  for i in 0..<len(Columns):
    echo "name :",Columns[i].name
    echo "tableName :",Columns[i].tableName
    echo "typ :",Columns[i].typ
    echo "position :",Columns[i].position
    echo "nullable :",Columns[i].nullable
    echo "maxchar :",Columns[i].maxchar
    echo "precision :",Columns[i].precision
    echo "scale :",Columns[i].scale
    echo "comment :",Columns[i].comment
    echo "---------------------------"

  echo "00000000000000000000"

  Db.sqlColInfo("FNBDOS",Columns )
  echo "---------------------------"
  for i in 0..<len(Columns):
    echo "name :",Columns[i].name
    echo "tableName :",Columns[i].tableName
    echo "typ :",Columns[i].typ
    echo "position :",Columns[i].position
    echo "nullable :",Columns[i].nullable
    echo "maxchar :",Columns[i].maxchar
    echo "precision :",Columns[i].precision
    echo "scale :",Columns[i].scale
    echo "comment :",Columns[i].comment
    echo "---------------------------"


  quitClean()

except STOP :
  echo "STOP " , getCurrentExceptionMsg()
except:
  echo "error : ", getCurrentExceptionMsg()
finally:
  clearRslt(Conn)
  closeDb(Db)