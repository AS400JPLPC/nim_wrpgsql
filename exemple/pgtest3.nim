import wrpgsql
import dcml
import zoned
import date



# specifique for test
import strformat
import terminal
import strutils


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

var Db2* : PGdb.Db
var Conn2* = new(PGsql)



# table 
type
  Actor* = object of RootObj
    actor_id: int
    first_name: Zoned
    last_name: Zoned
    last_update : Date


proc declare_Actor() :Actor =
  var Record : Actor
  Record.actor_id    = 0
  Record.first_name  = newZoned(45)
  Record.last_name   = newZoned(45)
  Record.last_update = newDate()
  return Record

var Rac : Actor = declare_Actor()

proc clear_Rac() =
  Rac.actor_id     = 0
  Rac.first_name  := ""
  Rac.last_name   := ""
  Rac.last_update := ""

proc  unpack_Rac(ConnSql : PGsql; r : int32 ) =
  clear_Rac()
  for r in 0 .. r :
    for f in 0 .. ConnSql.Field:
      case ConnSql.sqlName(f)

      of "actor_id" :
                  Rac.actor_id.fld(ConnSql,r, f)
      of "first_name" :
                  Rac.first_name.fld(ConnSql,r, f)
      of "last_name" :
                  Rac.last_name.fld(ConnSql,r, f)
      of "last_update" :
                  Rac.last_update.fld(ConnSql,r, f)



# view 
type
  Actor_info* = object of RootObj
    actor_id: int
    first_name: Zoned
    last_name: Zoned
    film_info : string


proc declare_Actor_info() :Actor_info =
  var Record : Actor_info
  Record.actor_id   = 0
  Record.first_name = newZoned(45)
  Record.last_name  = newZoned(45)
  Record.film_info  = ""
  return Record

var RacInfo : Actor_info = declare_Actor_info()

proc clear_RacInfo() =
  RacInfo.actor_id    = 0
  RacInfo.first_name := ""
  RacInfo.last_name  := ""
  RacInfo.film_info   = ""

proc  unpack_RacInfo(ConnSql : PGsql; r : int32 ) =
  clear_RacInfo()
  for r in 0 .. r :
    for f in 0 .. ConnSql.Field:
      case ConnSql.sqlName(f)

      of "actor_id" :
                  RacInfo.actor_id.fld(ConnSql,r, f)
      of "first_name" :
                  RacInfo.first_name.fld(ConnSql,r, f)
      of "last_name" :
                  RacInfo.last_name.fld(ConnSql,r, f)
      of "film_info" :
                  RacInfo.film_info.fld(ConnSql,r, f)
                  

# view 
type
  Sales_by_film_category* = object of RootObj
    category: Zoned
    total_sales: Dcml


proc declare_Sales_by_film_category() :Sales_by_film_category =
  var Record : Sales_by_film_category
  Record.category = newZoned(25,true)
  Record.total_sales  = newDcml(10,2,true)
  return Record

var Rsale : Sales_by_film_category = declare_Sales_by_film_category()

proc clear_Rsale () =
  Rsale .category    := ""
  Rsale .total_sales := "0"

proc  unpack_Rsale(ConnSql : PGsql; r : int32 ) =
  clear_Rsale()
  for r in 0 .. r :
    for f in 0 .. ConnSql.Field:
      case ConnSql.sqlName(f)

      of "category" :
                  Rsale.category.fld(ConnSql,r, f)
      of "total_sales" :
                  Rsale.total_sales.fld(ConnSql,r, f)





try :
  Db = Connect("localhost","5432","dvdrental","readonly","read","pgtest3-Read")
  echo "status : ",Db.status
  echo "Database : ",GetDb(Db)
  echo "GetUser : ", GetUser(Db)
  DbProd = Connect("localhost","5432","dvdrental","userpgm","usrpgm","pgtest3-USE")

#[
  Db2.sqlColInfo("tabletype",Columns )
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
]#

  Db.sqlColInfo("actor",Columns )
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


  requete =fmt"SELECT * FROM actor  ORDER BY actor_id LIMIT 10 ;" 
  Db.sqlQuery(Conn, requete )
  
  for r in 0 .. Conn.Rang :
    unpack_Rac(Conn,r) 
    echo "---------------------------"
    echo fmt" Id : {Rac.actor_id}  first_name : {Rac.first_name}  last_name : {Rac.last_name}  last_update : {Rac.last_update}"


  let f = open("actor_info.txt", fmWrite)


  requete =fmt"SELECT * FROM actor_info  ORDER BY actor_id ;" 
  Db.sqlQuery(Conn, requete )
  
  for r in 0 .. Conn.Rang :
    unpack_Rac_Info(Conn,r) 
    var line =   "---------------------------"
    f.writeLine(line)
    line =  fmt" Id : {RacInfo.actor_id}  first_name : {RacInfo.first_name}  last_name : {RacInfo.last_name}"
    f.writeLine(line)
    line =  fmt" film_info : {RacInfo.film_info}"
    f.writeLine(line)


  f.close()

 
  
  Db.sqlColInfo("sales_by_film_category",Columns )
  echo "---------------------------"
  for i in 0..<len(Columns):
    echo "name      :",Columns[i].name
    echo "tableName :",Columns[i].tableName
    echo "typ       :",Columns[i].typ
    echo "position  :",Columns[i].position
    echo "nullable  :",Columns[i].nullable
    echo "maxchar   :",Columns[i].maxchar
    echo "precision :",Columns[i].precision
    echo "scale     :",Columns[i].scale
    echo "comment   :",Columns[i].comment
    

  echo "---------------------------------------"
  requete =fmt"SELECT * FROM sales_by_film_category  ORDER BY category ;" 
  Db.sqlQuery(Conn, requete )
  echo alignLeft("Category",int(25)),"|",align("Somme",int(13))
  for r in 0 .. Conn.Rang :
    unpack_Rsale(Conn,r) 
    
    echo "---------------------------------------"
    echo fmt"{Rsale.category.alignLeft()}|{Rsale.total_sales.align(13)} "


except STOP :
  echo "STOP " , getCurrentExceptionMsg()
except:
  echo "error : ", getCurrentExceptionMsg()
finally:
  closeDb(Db)