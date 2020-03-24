import wrpgsql
import dcml
import zoned
import date


when not declared(strformat) :
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


type
  tabletype* = object of RootObj
    vdate: Date
    vnumeric: Dcml
    vtext: string
    vonchar : Zoned
    vheure : Temps
    vkey : Dcml
    vbool : bool
    vchar : Zoned

proc declare_Tabletype() :tabletype =
  var Record : tabletype
  Record.vdate = newDate()
  Record.vnumeric = newDcml(8,2)
  Record.vtext = ""
  Record.vonchar = newZoned(1)
  Record.vheure = newTemps()
  Record.vkey = newDcml(7,0,false)
  Record.vbool = false
  Record.vchar = newZoned(10)

  return Record

var Rcd : tabletype = declare_Tabletype()

proc clearRcd() =
  Rcd.vdate := ""
  Rcd.vnumeric := ""
  Rcd.vtext = ""
  Rcd.vonchar := ""
  Rcd.vheure := ""
  Rcd.vkey := 0
  Rcd.vbool = false
  Rcd.vchar := ""

proc  unpack_Rcd(ConnSql : PGsql; n : var  tabletype ; r : int32 ) =
  clearRcd()
  for r in 0 .. r :
    for f in 0 .. ConnSql.Field:
      case ConnSql.sqlName(f)

      of "vdate" :
                  Rcd.vdate.fld(ConnSql,r, f)
      of "vnumeric" :
                  Rcd.vnumeric.fld(ConnSql,r, f)
      of "vtext" :
                  Rcd.vtext.fld(ConnSql,r, f)
      of "vonchar" :
                  Rcd.vonchar.fld(ConnSql,r, f)
      of "vheure" :
                  Rcd.vheure.fld(ConnSql,r, f)
      of "vkey" :
                  Rcd.vkey.fld(ConnSql,r, f)
      of "vbool" :
                  Rcd.vbool.fld(ConnSql,r, f)
      of "vchar" :
                  Rcd.vchar.fld(ConnSql,r, f)




try :
  Db = Connect("localhost","5432","CGIFCH","readonly","read","pgtest2-Read")
  echo "status : ",Db.status
  echo "Database : ",GetDb(Db)
  echo "GetUser : ", GetUser(Db)
  DbProd = Connect("localhost","5432","CGIFCH","userpgm","usrpgm","pgtest2-USE")

#[
CREATE TABLE public.tabletype
(
    vdate date,
    vnumeric numeric(8,2),
    vtext text COLLATE pg_catalog."default",
    vonchar character(1) COLLATE pg_catalog."default",
    vheure time without time zone,
    vkey numeric(7,0) NOT NULL,
    vbool boolean DEFAULT false,
    vchar character(10) COLLATE pg_catalog."default",
    CONSTRAINT tabletype_pk PRIMARY KEY (vkey)
)
COMMENT ON TABLE public.tabletype
    IS 'test repertoir type';

COMMENT ON COLUMN public.tabletype.vdate
    IS 'filed date';

COMMENT ON COLUMN public.tabletype.vnumeric
    IS 'field  decimal (8,2)';

COMMENT ON COLUMN public.tabletype.vtext
    IS 'field text';

COMMENT ON COLUMN public.tabletype.vonchar
    IS 'field char';

COMMENT ON COLUMN public.tabletype.vheure
    IS 'field heure';

COMMENT ON COLUMN public.tabletype.vkey
    IS 'field  decimal (7,0)';

COMMENT ON COLUMN public.tabletype.vbool
    IS 'Test bool';

COMMENT ON COLUMN public.tabletype.vchar
    IS 'field char (10)';
  INSERT INTO public.tabletype
  (vdate, vnumeric, vtext, vonchar, vheure, vkey, vbool, vchar)
  VALUES('2051-10-12',1951.13, 'NOM JPL', 'C', '11:10:01', 101, true, 'jp-Laroche');
  
  INSERT INTO public.tabletype
  (vdate, vnumeric, vtext, vonchar, vheure, vkey, vbool, vchar)
  VALUES('2051-10-12',1951, '', 'Y', '11:10:01', 1011, true, 'jp-Marie');

  
 ]#
  

  try :
    Db.isTable("tabletype")
  except NOTFOUND :
    echo "NOT FOUND :" , getCurrentExceptionMsg()
    quitLine(167)
  
  requete =fmt"SELECT * FROM tabletype  ORDER BY vkey ;" 
  Db.sqlQuery(Conn, requete )
  
  for r in 0 .. Conn.Rang :
    unpack_Rcd(Conn,Rcd,r) 
    echo "---------------------------"
    echo "Rcd.vdate    ",Rcd.vdate
    echo "Rcd.vnumeric ",Rcd.vnumeric
    echo "Rcd.vtext    ",Rcd.vtext
    echo "Rcd.vonchar  ",Rcd.vonchar
    echo "Rcd.vheure   ",Rcd.vheure
    echo "Rcd.vkey     ",Rcd.vkey
    echo "Rcd.vbool    ",Rcd.vbool
    echo "Rcd.vchar    ",Rcd.vchar
    echo "---------------------------"




  requete =fmt"UPDATE tabletype SET vtext='tata'  WHERE vkey = 1011  ;" 

  DbProd.sqlQuery(ConnProd, requete )

  requete =fmt"SELECT vkey , vtext FROM tabletype  WHERE vkey = 1011 ORDER BY vkey ;" 
  Db.sqlQuery(Conn, requete )

  echo ""
  echo "---------------------------"
  for r in 0 .. Conn.Rang :
    Rcd.vkey.fld(Conn,r, 0)
    Rcd.vtext.fld(Conn,r, 1)
  echo "Rcd.vkey     ",Rcd.vkey
  echo "Rcd.vtext    ",Rcd.vtext
  echo "---------------------------"
  
  echo "pause : 204 "
  echo getch()




  var lock : bool =  true
  while lock == true :
    try :
      DbProd.Begin
      requete =fmt"SELECT * FROM tabletype  WHERE vkey = 101 ;" 
      DbProd.sqlLock(ConnProd, requete )
      #requete =fmt"UPDATE tabletype SET vtext='JPL'  WHERE vkey = 101 ;" 
      requete =fmt"DELETE FROM tabletype   WHERE vkey = 101 ;" 
      DbProd.sqlQuery(ConnProd, requete )
      DbProd.Commit
      DbProd.Begin

      Rcd.vdate:="2020-10-20"
      Rcd.vnumeric:=5000
      #Rcd.vnumeric:=0
      requete =fmt"""INSERT INTO tabletype
      (vdate, vnumeric, vtext, vonchar, vheure, vkey, vbool, vchar)
      VALUES({Rcd.vdate.sql()},{Rcd.vnumeric.sql()}, 'JPL', 'C', '11:10:01', 101, true, 'jp-Laroche');""" 

      DbProd.sqlQuery(ConnProd, requete) 
      
      echo "pause : 231"
      echo getch()

      DbProd.Commit
      lock = false

    except LOCK :
      echo "LOCK :" , getCurrentExceptionMsg()
      DbProd.Rollback
      Sleep(1000)
    except NOTFOUND :
      echo "NOT FOUND :" , getCurrentExceptionMsg()
      DbProd.Rollback
      lock = false
    except ERRSQL :
      echo "ERR SQL :" , getCurrentExceptionMsg()
      DbProd.Rollback
      echo "il y a un beug veuillez corriger"
      lock = false


  requete =fmt"SELECT * FROM tabletype  WHERE vkey = 101 ORDER BY vkey ;" 
  Db.sqlQuery(Conn, requete )

  echo ""
  for r in 0 .. Conn.Rang :
    unpack_Rcd(Conn,Rcd,r) 
    echo "---------------------------"
    echo "Rcd.vdate    ",Rcd.vdate
    echo "Rcd.vnumeric ",Rcd.vnumeric
    echo "Rcd.vtext    ",Rcd.vtext
    echo "Rcd.vonchar  ",Rcd.vonchar
    echo "Rcd.vheure   ",Rcd.vheure
    echo "Rcd.vkey     ",Rcd.vkey
    echo "Rcd.vbool    ",Rcd.vbool
    echo "Rcd.vchar    ",Rcd.vchar
    echo "---------------------------"


  echo "pause : 270 "
  echo getch()

  DbProd.Begin
  requete =fmt"SELECT * FROM tabletype    WHERE vkey = 101 ;" 
  DbProd.sqlLock(ConnProd, requete )
  Rcd.vbool =true
  requete =fmt"UPDATE tabletype SET vtext='totsxxxx', vbool = {Rcd.vbool}, vchar = null WHERE vkey = 101  ;" 
  DbProd.sqlQuery(ConnProd, requete )

  echo "pause : 280 "
  echo getch()
  
  DbProd.Commit

  try:
    requete =fmt"UPDATE tabletype SET vtextx='totsxxxx' WHERE vkey = 10100  ;"
    DbProd.sqlQuery(ConnProd, requete )
  except NOTFOUND :
    echo "NOT FOUND :" , getCurrentExceptionMsg()
  except ERRSQL :
    echo "ERR SQL :" , getCurrentExceptionMsg()
  echo "pause : 292 "
  echo getch()

  try:
    requete =fmt"""INSERT INTO tabletype
    (vdate, vnumeric, vtext, vonchar, vheure, vkey, vbool, vchar)
    VALUES('1951-10-12',5000, 'JPL', 'C', '11:10:01', 101, true, 'jp-Laroche');"""
    DbProd.sqlQuery(ConnProd, requete )
  except NOTFOUND :
    echo "NOT FOUND :" , getCurrentExceptionMsg()
  except ERRSQL :
    echo "ERR SQL :" , getCurrentExceptionMsg()
  echo "pause : 304 "
  echo getch()

  requete =fmt"SELECT vkey,vtext  FROM tabletype   ORDER BY vkey ;" 
  Db.sqlQuery(Conn, requete )
  echo ""
  echo "------read key ------------"
  for r in 0 .. Conn.Rang :
    Rcd.vkey.fld(Conn,r, 0)
    Rcd.vtext.fld(Conn,r, 1)
    echo "Rcd.vkey     ",Rcd.vkey
    echo "Rcd.vtext    ",Rcd.vtext
  echo "---------------------------"

  echo "pause : 318 "
  echo getch()

  echo "---no rescpet order field--"
  clearRcd()
  try :
    requete =fmt"SELECT vkey, vtext,vdate,vnumeric,vonchar,vheure,vchar,vbool  FROM tabletype   ORDER BY vkey ;" 
    Db.sqlQuery(Conn, requete )

    for r in 0 .. Conn.Rang :
      unpack_Rcd(Conn,Rcd,r) 
      echo ""
      echo "---------------------------"
      echo "Rcd.vdate    ",Rcd.vdate
      echo "Rcd.vnumeric ",Rcd.vnumeric
      echo "Rcd.vtext    ",Rcd.vtext
      echo "Rcd.vonchar  ",Rcd.vonchar
      echo "Rcd.vheure   ",Rcd.vheure
      echo "Rcd.vkey     ",Rcd.vkey
      echo "Rcd.vbool    ",Rcd.vbool
      echo "Rcd.vchar    ",Rcd.vchar
      echo "---------------------------"

    echo "num col :",Conn.sqlNumber("vkey")

    requete =fmt"SELECT *  FROM tabletype WHERE vkey = 1012  ORDER BY vkey ;" 
    Db.sqlQuery(Conn, requete )
  except NOTFOUND :
    echo "NOT FOUND :" , "client 1012 non trouvé"
    echo getCurrentExceptionMsg()
  finally:
    echo "suite"

  echo Rcd.vdate.sql()
  echo Rcd.vheure.sql()
  requete =fmt"SELECT *  FROM tabletype WHERE vkey = 101  ORDER BY vkey ;" 
  Db.sqlQuery(Conn, requete )
  for r in 0 .. Conn.Rang :
    unpack_Rcd(Conn,Rcd,r) 
  echo ""
  echo ""
  echo fmt"SELECT *  FROM tabletype WHERE vkey = 101  ORDER BY vkey ;" 
  echo ""
  echo "---------------------------"
  echo "Rcd.vdate    ",Rcd.vdate.sql()
  echo "Rcd.vnumeric ",Rcd.vnumeric.sql()
  echo "Rcd.vtext    ",Rcd.vtext
  echo "Rcd.vonchar  ",Rcd.vonchar.sql()
  echo "Rcd.vheure   ",Rcd.vheure.sql()
  echo "Rcd.vkey     ",Rcd.vkey.sql()
  echo "Rcd.vbool    ",Rcd.vbool
  echo "Rcd.vchar    ",Rcd.vchar.sql()
  echo "---------------------------"

  echo "Rcd.vnumeric ",Rcd.vnumeric.isBool()
  quitClean()


except STOP :
  echo "STOP " , getCurrentExceptionMsg()
except:
  echo "error : ", getCurrentExceptionMsg()
finally:
  closeDb(Db)