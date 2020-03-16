when not declared(os) :
  from os import getenv
  from os import sleep
when not declared(strutils) :
  import strutils
when not declared(postgres) :
  import postgres 
when not declared(strformat) :
  import strformat
when not declared(dcml) :
  import dcml
when not declared(zoned) :
  import zoned


when not declared(PGsql) :
  type 
    PGsql* = ref object of RootObj
      Rows*   : int32
      Cols*   : int32
      Eof*    : bool
      Rslt*   : PPGresult
      Rang*   : int32
      Field*  : int32

  type 
    PGdb* = ref object of RootObj
      Db : PPGconn 

  type
    LOCK* = object of IOError
    NOTFOUND* = object of IOError
    ERRSQL* = object of IOError

    DbTypeKind* = enum ## a superset of datatypes that might be supported.
      dbUnknown,       ## unknown datatype
      dbSerial,        ## datatype used for primary auto-increment keys
      dbNull,          ## datatype used for the NULL value
      dbBit,           ## bit datatype
      dbBool,          ## boolean datatype
      dbBlob,          ## blob datatype
      dbFixedChar,     ## string of fixed length
      dbVarchar,       ## string datatype
      dbJson,          ## JSON datatype
      dbXml,           ## XML datatype
      dbInt,           ## some integer type
      dbUInt,          ## some unsigned integer type
      dbDecimal,       ## decimal numbers (fixed-point number)
      dbFloat,         ## some floating point type
      dbDate,          ## a year-month-day description
      dbTime,          ## HH:MM:SS information
      dbDatetime,      ## year-month-day and HH:MM:SS information,
                       ## plus optional time or timezone information
      dbTimestamp,     ## Timestamp values are stored as the number of seconds
                       ## since the epoch ('1970-01-01 00:00:00' UTC).
      dbTimeInterval,  ## an interval [a,b] of times
      dbEnum,          ## some enum
      dbSet,           ## set of enum values
      dbArray,         ## an array of values
      dbComposite,     ## composite type (record, struct, etc)
      dbUrl,           ## a URL
      dbUuid,          ## a UUID
      dbInet,          ## an IP address
      dbMacAddress,    ## a MAC address
      dbGeometry,      ## some geometric type
      dbPoint,         ## Point on a plane   (x,y)
      dbLine,          ## Infinite line ((x1,y1),(x2,y2))
      dbLseg,          ## Finite line segment   ((x1,y1),(x2,y2))
      dbBox,           ## Rectangular box   ((x1,y1),(x2,y2))
      dbPath,          ## Closed or open path (similar to polygon) ((x1,y1),...)
      dbPolygon,       ## Polygon (similar to closed path)   ((x1,y1),...)
      dbCircle,        ## Circle   <(x,y),r> (center point and radius)
      dbUser1,         ## user definable datatype 1 (for unknown extensions)
      dbUser2,         ## user definable datatype 2 (for unknown extensions)
      dbUser3,         ## user definable datatype 3 (for unknown extensions)
      dbUser4,         ## user definable datatype 4 (for unknown extensions)
      dbUser5          ## user definable datatype 5 (for unknown extensions)

    DbType* = object              ## describes a database type
      kind*: DbTypeKind           ## the kind of the described type
      name*: string               ## the name of the type

    DbColumn* = object   ## information about a database column
      name*: string      ## name of the column
      tableName*: string ## name of the table the column belongs to (optional)
      typ*: DbType        ## type of the column
      position*  : int    ## ORDINAL_POSITION
      maxchar*   : int    ## CHARACTER_MAXIMUM_LENGTH
      precision* : int    ## NUMERIC_PRECISION
      scale*     : int    ## NUMERIC_SCALE
      comment*   : string ## information comment column

    DbColumns* = seq[DbColumn]

  
  proc pgErrLock(msg: string) {.noreturn, noinline.} =
    ## raises an pgErrSQL exception with message `msg`.
    var e: ref LOCK
    new(e)
    e.msg = msg
    raise e

  proc pgNotFound(msg: string) {.noreturn, noinline.} =
    ## raises an pgErrSQL exception with message `msg`.
    var e: ref NOTFOUND
    new(e)
    e.msg = msg
    raise e

  proc pgErrSQL(db: PPGconn) {.noreturn, noinline.} =
    ## raises an pgErrSQL exception with message `msg`.
    var e: ref ERRSQL
    new(e)
    e.msg = $pqErrorMessage(db)
    raise e

  proc pgErrSQL(msg: string) {.noreturn, noinline.} =
    ## raises an pgErrSQL exception with message `msg`.
    var e: ref ERRSQL
    new(e)
    e.msg = msg
    raise e

  proc Sleep*(s:int) = sleep(s)

  ## Connect 
  proc Connect*(host, port, database, user, password , application: string) : PPGconn =
    var UserName : string = getenv("LOGNAME")
    var conninfo : cstring = fmt"host={host}  port={port}  dbname={database}  user={user}  password={password} application_name={UserName}-{application}"
    result = pqconnectdb(conninfo)
    if pqStatus(result) != CONNECTION_OK: pgErrSQL(result) 

  proc closeDb*(db: PPGconn) =
    if db != nil:
      pqfinish(db)

  proc clearRslt*(ConnSql : PGsql) =
    pqClear(ConnSql.Rslt)

  proc GetDb*(db: PPGconn) : string =
    return $pqdb(db)

  proc GetUser*(db: PPGconn) : string =
    return $pquser(db)


  proc GetPassword*(db: PPGconn) : string =
    return $pqpass(db)

  proc GetHost*(db: PPGconn) : string =
    return $pqhost(db)

  proc GetPort*(db: PPGconn) : string =
    return $pqport(db)


  proc Begin*(db: PPGconn) =
    var res:PPGresult
    res = pqexec(db,"BEGIN ;")
    if pqresultStatus(res) != PGRES_COMMAND_OK : pgErrSQL(db) 
    pqClear(res)
    res = pqexec(db,"SET SESSION CHARACTERISTICS AS TRANSACTION  ISOLATION LEVEL SERIALIZABLE ;")
    if pqresultStatus(res) != PGRES_COMMAND_OK : pgErrSQL(db) 
    pqClear(res)

  proc Commit*(db: PPGconn) =
    var res:PPGresult = pqexec(db,"COMMIT;") 
    if pqresultStatus(res) != PGRES_COMMAND_OK : pgErrSQL(db) 
    pqClear(res)

  proc Rollback*(db: PPGconn) =
    var res:PPGresult = pqexec(db,"ROLLBACK;") 
    if pqresultStatus(res) != PGRES_COMMAND_OK : pgErrSQL(db) 
    pqClear(res)

  proc Savepoint*(db: PPGconn) =
    var res:PPGresult = pqexec(db,"SAVEPOINT full_savepoint;") 
    if pqresultStatus(res) != PGRES_COMMAND_OK : pgErrSQL(db) 
    pqClear(res)


  proc SavepointRollback*(db: PPGconn) =
    var res:PPGresult = pqexec(db,"ROLLBACK TO SAVEPOINT full_savepoint;") 
    if pqresultStatus(res) != PGRES_COMMAND_OK : pgErrSQL(db) 
    pqClear(res)


  proc SavepointRelease*(db: PPGconn) =
    var res:PPGresult = pqexec(db,"RELEASE SAVEPOINT full_savepoint;") 
    if pqresultStatus(res) != PGRES_COMMAND_OK : pgErrSQL(db) 
    pqClear(res)



  proc isTable*(db: PPGconn; name: string) =
    var requete : string= fmt"""SELECT count(*)  FROM pg_tables  WHERE  schemaname ='public' AND    tablename = '{name}';"""
    var count :int = parseInt($pqgetvalue(pqexec(db,requete), 0, 0))
    if count  == 0 : 
      pgNotFound(fmt"no exsite Table : {name}")


  proc sqlValue*(ConnSql : PGsql; nRang, nField : int32) : string =
    result  = $pqgetvalue(ConnSql.Rslt,nRang, nField)
    if pqresultStatus(ConnSql.Rslt)  == PGRES_FATAL_ERROR or nRang  < 0 or nRang > ConnSql.Rang or nField < 0 or nField > ConnSql.Cols  :
      pgErrSQL(fmt"sqlValue invalide  Rang:{nRang} field : {nField}")

  proc sqlName*(ConnSql : PGsql; nField : int32) : string =
    result  = $pqfname(ConnSql.Rslt,nField)
    if pqresultStatus(ConnSql.Rslt)  == PGRES_FATAL_ERROR or nField < 0 or nField > ConnSql.Cols  :
      pgErrSQL(fmt"sqlName invalide field : {nField}")

  proc sqlNumber*(ConnSql : PGsql; nName : string) : int32 =
        result  = pqfnumber(ConnSql.Rslt,nName)
        if pqresultStatus(ConnSql.Rslt)  == PGRES_FATAL_ERROR or result  == -1 :
          pgErrSQL(fmt"sqlNumber invalide field : {nName}")
  
  proc sqlisNul*(ConnSql : PGsql; nRang, nField : int32) : bool =
    var i : int =  pqgetisnull(ConnSql.Rslt,nRang, nField) 
    if pqresultStatus(ConnSql.Rslt)  == PGRES_FATAL_ERROR or nRang  < 0 or nRang > ConnSql.Rang or nField < 0 or nField > ConnSql.Cols  :
      pgErrSQL(fmt"sqlisNul invalide  Rang:{nRang} field : {nField}")
    if i == 1 : return true  else : return false

  proc sqlLen*(ConnSql : PGsql; nRang, nField : int32) : int =
    result = pqgetlength(ConnSql.Rslt,nRang, nField)
    if pqresultStatus(ConnSql.Rslt)  == PGRES_FATAL_ERROR or nRang  < 0 or nRang > ConnSql.Rang or nField < 0 or nField > ConnSql.Cols  :
      pgErrSQL(fmt"sqlLen invalide  Rang:{nRang} field : {nField}")

  proc oidType(oid:int) : DbType =
    case oid
    of 16: return DbType(kind: DbTypeKind.dbBool, name: "bool")
    of 17: return DbType(kind: DbTypeKind.dbBlob, name: "bytea")
  
    of 21:   return DbType(kind: DbTypeKind.dbInt, name: "int2")
    of 23:   return DbType(kind: DbTypeKind.dbInt, name: "int4")
    of 20:   return DbType(kind: DbTypeKind.dbInt, name: "int8")
    of 1560: return DbType(kind: DbTypeKind.dbBit, name: "bit")
    of 1562: return DbType(kind: DbTypeKind.dbInt, name: "varbit")
  
    of 18:   return DbType(kind: DbTypeKind.dbFixedChar, name: "char")
    of 19:   return DbType(kind: DbTypeKind.dbFixedChar, name: "name")
    of 1042: return DbType(kind: DbTypeKind.dbFixedChar, name: "bpchar")
  
    of 25:   return DbType(kind: DbTypeKind.dbVarchar, name: "text")
    of 1043: return DbType(kind: DbTypeKind.dbVarChar, name: "varchar")
    of 2275: return DbType(kind: DbTypeKind.dbVarchar, name: "cstring")
  
    of 700: return DbType(kind: DbTypeKind.dbFloat, name: "float4")
    of 701: return DbType(kind: DbTypeKind.dbFloat, name: "float8")
  
    of 790:  return DbType(kind: DbTypeKind.dbDecimal, name: "money")
    of 1700: return DbType(kind: DbTypeKind.dbDecimal, name: "numeric")
  
    of 704:  return DbType(kind: DbTypeKind.dbTimeInterval, name: "tinterval")
    of 702:  return DbType(kind: DbTypeKind.dbTimestamp, name: "abstime")
    of 703:  return DbType(kind: DbTypeKind.dbTimeInterval, name: "reltime")
    of 1082: return DbType(kind: DbTypeKind.dbDate, name: "date")
    of 1083: return DbType(kind: DbTypeKind.dbTime, name: "time")
    of 1114: return DbType(kind: DbTypeKind.dbTimestamp, name: "timestamp")
    of 1184: return DbType(kind: DbTypeKind.dbTimestamp, name: "timestamptz")
    of 1186: return DbType(kind: DbTypeKind.dbTimeInterval, name: "interval")
    of 1266: return DbType(kind: DbTypeKind.dbTime, name: "timetz")
  
    of 114:  return DbType(kind: DbTypeKind.dbJson, name: "json")
    of 142:  return DbType(kind: DbTypeKind.dbXml, name: "xml")
    of 3802: return DbType(kind: DbTypeKind.dbJson, name: "jsonb")
  
    of 600: return DbType(kind: DbTypeKind.dbPoint, name: "point")
    of 601: return DbType(kind: DbTypeKind.dbLseg, name: "lseg")
    of 602: return DbType(kind: DbTypeKind.dbPath, name: "path")
    of 603: return DbType(kind: DbTypeKind.dbBox, name: "box")
    of 604: return DbType(kind: DbTypeKind.dbPolygon, name: "polygon")
    of 628: return DbType(kind: DbTypeKind.dbLine, name: "line")
    of 718: return DbType(kind: DbTypeKind.dbCircle, name: "circle")
  
    of 650: return DbType(kind: DbTypeKind.dbInet, name: "cidr")
    of 829: return DbType(kind: DbTypeKind.dbMacAddress, name: "macaddr")
    of 869: return DbType(kind: DbTypeKind.dbInet, name: "inet")
  
    of 2950: return DbType(kind: DbTypeKind.dbVarchar, name: "uuid")
    of 3614: return DbType(kind: DbTypeKind.dbVarchar, name: "tsvector")
    of 3615: return DbType(kind: DbTypeKind.dbVarchar, name: "tsquery")
    of 2970: return DbType(kind: DbTypeKind.dbVarchar, name: "txid_snapshot")
  
    of 27:   return DbType(kind: DbTypeKind.dbComposite, name: "tid")
    of 1790: return DbType(kind: DbTypeKind.dbComposite, name: "refcursor")
    of 2249: return DbType(kind: DbTypeKind.dbComposite, name: "record")
    of 3904: return DbType(kind: DbTypeKind.dbComposite, name: "int4range")
    of 3906: return DbType(kind: DbTypeKind.dbComposite, name: "numrange")
    of 3908: return DbType(kind: DbTypeKind.dbComposite, name: "tsrange")
    of 3910: return DbType(kind: DbTypeKind.dbComposite, name: "tstzrange")
    of 3912: return DbType(kind: DbTypeKind.dbComposite, name: "daterange")
    of 3926: return DbType(kind: DbTypeKind.dbComposite, name: "int8range")
  
    of 22:   return DbType(kind: DbTypeKind.dbArray, name: "int2vector")
    of 30:   return DbType(kind: DbTypeKind.dbArray, name: "oidvector")
    of 143:  return DbType(kind: DbTypeKind.dbArray, name: "xml[]")
    of 199:  return DbType(kind: DbTypeKind.dbArray, name: "json[]")
    of 629:  return DbType(kind: DbTypeKind.dbArray, name: "line[]")
    of 651:  return DbType(kind: DbTypeKind.dbArray, name: "cidr[]")
    of 719:  return DbType(kind: DbTypeKind.dbArray, name: "circle[]")
    of 791:  return DbType(kind: DbTypeKind.dbArray, name: "money[]")
    of 1000: return DbType(kind: DbTypeKind.dbArray, name: "bool[]")
    of 1001: return DbType(kind: DbTypeKind.dbArray, name: "bytea[]")
    of 1002: return DbType(kind: DbTypeKind.dbArray, name: "char[]")
    of 1003: return DbType(kind: DbTypeKind.dbArray, name: "name[]")
    of 1005: return DbType(kind: DbTypeKind.dbArray, name: "int2[]")
    of 1006: return DbType(kind: DbTypeKind.dbArray, name: "int2vector[]")
    of 1007: return DbType(kind: DbTypeKind.dbArray, name: "int4[]")
    of 1008: return DbType(kind: DbTypeKind.dbArray, name: "regproc[]")
    of 1009: return DbType(kind: DbTypeKind.dbArray, name: "text[]")
    of 1028: return DbType(kind: DbTypeKind.dbArray, name: "oid[]")
    of 1010: return DbType(kind: DbTypeKind.dbArray, name: "tid[]")
    of 1011: return DbType(kind: DbTypeKind.dbArray, name: "xid[]")
    of 1012: return DbType(kind: DbTypeKind.dbArray, name: "cid[]")
    of 1013: return DbType(kind: DbTypeKind.dbArray, name: "oidvector[]")
    of 1014: return DbType(kind: DbTypeKind.dbArray, name: "bpchar[]")
    of 1015: return DbType(kind: DbTypeKind.dbArray, name: "varchar[]")
    of 1016: return DbType(kind: DbTypeKind.dbArray, name: "int8[]")
    of 1017: return DbType(kind: DbTypeKind.dbArray, name: "point[]")
    of 1018: return DbType(kind: DbTypeKind.dbArray, name: "lseg[]")
    of 1019: return DbType(kind: DbTypeKind.dbArray, name: "path[]")
    of 1020: return DbType(kind: DbTypeKind.dbArray, name: "box[]")
    of 1021: return DbType(kind: DbTypeKind.dbArray, name: "float4[]")
    of 1022: return DbType(kind: DbTypeKind.dbArray, name: "float8[]")
    of 1023: return DbType(kind: DbTypeKind.dbArray, name: "abstime[]")
    of 1024: return DbType(kind: DbTypeKind.dbArray, name: "reltime[]")
    of 1025: return DbType(kind: DbTypeKind.dbArray, name: "tinterval[]")
    of 1027: return DbType(kind: DbTypeKind.dbArray, name: "polygon[]")
    of 1040: return DbType(kind: DbTypeKind.dbArray, name: "macaddr[]")
    of 1041: return DbType(kind: DbTypeKind.dbArray, name: "inet[]")
    of 1263: return DbType(kind: DbTypeKind.dbArray, name: "cstring[]")
    of 1115: return DbType(kind: DbTypeKind.dbArray, name: "timestamp[]")
    of 1182: return DbType(kind: DbTypeKind.dbArray, name: "date[]")
    of 1183: return DbType(kind: DbTypeKind.dbArray, name: "time[]")
    of 1185: return DbType(kind: DbTypeKind.dbArray, name: "timestamptz[]")
    of 1187: return DbType(kind: DbTypeKind.dbArray, name: "interval[]")
    of 1231: return DbType(kind: DbTypeKind.dbArray, name: "numeric[]")
    of 1270: return DbType(kind: DbTypeKind.dbArray, name: "timetz[]")
    of 1561: return DbType(kind: DbTypeKind.dbArray, name: "bit[]")
    of 1563: return DbType(kind: DbTypeKind.dbArray, name: "varbit[]")
    of 2201: return DbType(kind: DbTypeKind.dbArray, name: "refcursor[]")
    of 2951: return DbType(kind: DbTypeKind.dbArray, name: "uuid[]")
    of 3643: return DbType(kind: DbTypeKind.dbArray, name: "tsvector[]")
    of 3645: return DbType(kind: DbTypeKind.dbArray, name: "tsquery[]")
    of 3807: return DbType(kind: DbTypeKind.dbArray, name: "jsonb[]")
    of 2949: return DbType(kind: DbTypeKind.dbArray, name: "txid_snapshot[]")
    of 3905: return DbType(kind: DbTypeKind.dbArray, name: "int4range[]")
    of 3907: return DbType(kind: DbTypeKind.dbArray, name: "numrange[]")
    of 3909: return DbType(kind: DbTypeKind.dbArray, name: "tsrange[]")
    of 3911: return DbType(kind: DbTypeKind.dbArray, name: "tstzrange[]")
    of 3913: return DbType(kind: DbTypeKind.dbArray, name: "daterange[]")
    of 3927: return DbType(kind: DbTypeKind.dbArray, name: "int8range[]")
    of 2287: return DbType(kind: DbTypeKind.dbArray, name: "record[]")
  
    of 705:  return DbType(kind: DbTypeKind.dbUnknown, name: "unknown")
    else: return DbType(kind: DbTypeKind.dbUnknown, name: $oid) 
    ## Query the system table pg_type to determine exactly which type is referenced.


  proc sqlType*(ConnSql : PGsql; nField : int32) : DbType =
    var oid:int = ConnSql.Rslt.pqftype(nField)
    if oid == 0:
      pgErrSQL(fmt"type invalide field : {nField}")
    return  oidType(oid)





  ##----------- SQL QUERY/PAGE/FIRST/LAST/NEXT/PRIOR/LOCK------------

  proc sqlQuery*(db: PPGconn; ConnSql : Pgsql; query :string )=
    ConnSql.Rows = 0
    ConnSql.Cols = 0
    ConnSql.Rang = 0
    ConnSql.Field = 0

    if contains(query, "select") or contains(query, "SELECT") or
        contains(query, "update") or contains(query, "UPDATE") or
        contains(query, "delete") or contains(query, "DELETE") or
        contains(query, "insert") or contains(query, "INSERT") :
      
      ConnSql.Rslt = pqexec(db,query)
      if pqresultStatus(ConnSql.Rslt) == PGRES_FATAL_ERROR:
        pgErrSQL(db)


      let operation : string  =fmt"{pqcmdStatus(ConnSql.Rslt)}"
      case operation
        of "SELECT 0","UPDATE 0","DELETE 0"  :
          pqClear(ConnSql.Rslt)
          pgNotFound(fmt"Proc sqlQuery : {query}")
        else :
          ConnSql.Rows = pqntuples(ConnSql.Rslt)
          ConnSql.Cols = pqnfields(ConnSql.Rslt)
          ConnSql.Rang = (pqntuples(ConnSql.Rslt) - 1)
          ConnSql.Field = (pqnfields(ConnSql.Rslt) - 1)

    else : pgErrSQL(fmt"Proc sqlQuery Only SELECT UPDATE DELETE INSERT : {query}")



  proc sqlPage*(db: PPGconn; ConnSql : Pgsql; query :string ; limit : int)=
    ConnSql.Rows = 0
    ConnSql.Cols = 0
    ConnSql.Rang = 0
    ConnSql.Field = 0
    var requete : string = query.replace(";"," ")
    requete = fmt"{requete} LIMIT {limit};"
    if contains(requete, "select") or contains(requete, "SELECT") :
      if contains(requete, "order by") or contains(requete, "ORDER BY") :
        ConnSql.Rslt = pqexec(db,requete)

        if pqresultStatus(ConnSql.Rslt) != PGRES_TUPLES_OK or pqresultStatus(ConnSql.Rslt) == PGRES_FATAL_ERROR:
          pgErrSQL(db)
        
        let operation : string  =fmt"{pqcmdStatus(ConnSql.Rslt)}"

        case operation 
          of "SELECT 0":
            pqClear(ConnSql.Rslt)
            pgNotFound(fmt"Proc sqlQuery : {requete}")
          else :
            ConnSql.Rows = pqntuples(ConnSql.Rslt)
            ConnSql.Cols = pqnfields(ConnSql.Rslt)
            ConnSql.Rang = (pqntuples(ConnSql.Rslt) - 1)
            ConnSql.Field = (pqnfields(ConnSql.Rslt) - 1)

      else : pgErrSQL(fmt"Proc sqlPage requires ORDER BY : {requete}")
    else : pgErrSQL(fmt"Proc sqlPage Only SELECT: {requete}")


  proc sqlFirst*(db: PPGconn; ConnSql : Pgsql; query ,cursor :string )=
    ConnSql.Rows = 0
    ConnSql.Cols = 0
    ConnSql.Rang = 0
    ConnSql.Field = 0

    var requete : string = fmt"DECLARE {cursor} CURSOR FOR {query}"
    ConnSql.Rslt = pqexec(db,requete)
    if pqresultStatus(ConnSql.Rslt) != PGRES_COMMAND_OK  or pqresultStatus(ConnSql.Rslt) == PGRES_FATAL_ERROR :
      pgErrSQL(db)

    requete = fmt"FETCH FIRST in {cursor};" 
    ConnSql.Rslt = pqexec(db,requete)

    case pqresultStatus(ConnSql.Rslt)
      of PGRES_TUPLES_OK :
        let operation : string  =fmt"{pqcmdStatus(ConnSql.Rslt)}"
        if operation == "FETCH 0" :
          ConnSql.Eof  =true
          requete = fmt"close  {cursor};"
          discard pqexec(db,requete)
          pgNotFound(fmt"Proc sqlFirst : {query} cursor : {cursor}")
        else :
          ConnSql.Eof  =false
          ConnSql.Rows = pqntuples(ConnSql.Rslt)
          ConnSql.Cols = pqnfields(ConnSql.Rslt)
          ConnSql.Rang = (pqntuples(ConnSql.Rslt) - 1)
          ConnSql.Field = (pqnfields(ConnSql.Rslt) - 1)
      else :
        ConnSql.Eof  =true
        pgErrSQL(db)


  proc sqlLast*(db: PPGconn; ConnSql : Pgsql; query ,cursor :string )=
    ConnSql.Rows = 0
    ConnSql.Cols = 0
    ConnSql.Rang = 0
    ConnSql.Field = 0

    var requete : string = fmt"DECLARE {cursor} CURSOR FOR {query}"
    ConnSql.Rslt = pqexec(db,requete)
    if pqresultStatus(ConnSql.Rslt) != PGRES_COMMAND_OK  or pqresultStatus(ConnSql.Rslt) == PGRES_FATAL_ERROR:
      pgErrSQL(db)

    requete = fmt"FETCH LAST in {cursor};" 
    ConnSql.Rslt = pqexec(db,requete)

    case pqresultStatus(ConnSql.Rslt)
      of PGRES_TUPLES_OK :
        let operation : string  =fmt"{pqcmdStatus(ConnSql.Rslt)}"
        if operation == "FETCH 0" :
          ConnSql.Eof  =true
          requete = fmt"close  {cursor};"
          discard pqexec(db,requete)
          pgNotFound(fmt"Proc sqlLast : {query} cursor : {cursor}")
        else :
          ConnSql.Eof  =false
          ConnSql.Rows = pqntuples(ConnSql.Rslt)
          ConnSql.Cols = pqnfields(ConnSql.Rslt)
          ConnSql.Rang = (pqntuples(ConnSql.Rslt) - 1)
          ConnSql.Field = (pqnfields(ConnSql.Rslt) - 1)
      else :
        ConnSql.Eof  =true
        pgErrSQL(db)


  proc sqlNext*(db: PPGconn; ConnSql : Pgsql;cursor :string )=
    ConnSql.Rows = 0
    ConnSql.Cols = 0
    ConnSql.Rang = 0
    ConnSql.Field = 0

    var requete : string = fmt"FETCH NEXT in  {cursor};" 
    ConnSql.Rslt = pqexec(db,requete)

    case pqresultStatus(ConnSql.Rslt)
      of PGRES_TUPLES_OK :
        let operation : string  =fmt"{pqcmdStatus(ConnSql.Rslt)}"
        if operation == "FETCH 0" :
          ConnSql.Eof  =true
          requete = fmt"close  {cursor};"
          discard pqexec(db,requete)
        else :
          ConnSql.Eof  =false
          ConnSql.Rows = pqntuples(ConnSql.Rslt)
          ConnSql.Cols = pqnfields(ConnSql.Rslt)
          ConnSql.Rang = (pqntuples(ConnSql.Rslt) - 1)
          ConnSql.Field = (pqnfields(ConnSql.Rslt) - 1)
      else :
        ConnSql.Eof  =true
        pgErrSQL(db)

  proc sqlPrior*(db: PPGconn; ConnSql : Pgsql;cursor :string )=
    ConnSql.Rows = 0
    ConnSql.Cols = 0
    ConnSql.Rang = 0
    ConnSql.Field = 0

    var requete : string = fmt"FETCH PRIOR in  {cursor};" 
    ConnSql.Rslt = pqexec(db,requete)

    case pqresultStatus(ConnSql.Rslt)
      of PGRES_TUPLES_OK :
        let operation : string  =fmt"{pqcmdStatus(ConnSql.Rslt)}"
        if operation == "FETCH 0" :
          ConnSql.Eof  =true
          requete = fmt"close  {cursor};"
          discard pqexec(db,requete)
        else :
          ConnSql.Eof  =false
          ConnSql.Rows = pqntuples(ConnSql.Rslt)
          ConnSql.Cols = pqnfields(ConnSql.Rslt)
          ConnSql.Rang = (pqntuples(ConnSql.Rslt) - 1)
          ConnSql.Field = (pqnfields(ConnSql.Rslt) - 1)
      else :
        ConnSql.Eof  =true
        pgErrSQL(db)
  
  
  proc sqlLock*(db: PPGconn; ConnSql : Pgsql; query :string )=
    ConnSql.Rows = 0
    ConnSql.Cols = 0
    ConnSql.Rang = 0
    ConnSql.Field = 0
    if contains(query, "select") or contains(query, "SELECT") :
      var requete : string = query.replace(";"," ")
      requete = fmt"{requete} FOR UPDATE NOWAIT;"
      ConnSql.Rslt = pqexec(db,requete)
      if pqresultStatus(ConnSql.Rslt) != PGRES_TUPLES_OK or pqresultStatus(ConnSql.Rslt) == PGRES_FATAL_ERROR:
        pgErrSQL(db)

      let operation : string  =fmt"{pqcmdStatus(ConnSql.Rslt)}"
      case operation 
        of "SELECT 1" :
          ConnSql.Rows = pqntuples(ConnSql.Rslt)
          ConnSql.Cols = pqnfields(ConnSql.Rslt)
          ConnSql.Rang = (pqntuples(ConnSql.Rslt) - 1)
          ConnSql.Field = (pqnfields(ConnSql.Rslt) - 1)
        of "SELECT 0" :
          pqClear(ConnSql.Rslt)
          pgNotFound(fmt"Proc sqlLock {requete}")
        else :
          pqClear(ConnSql.Rslt)
          pgErrSQL(db)
    else :
      pgErrSQL("""sqlLock: parameter Only SELECT """)


  #-----------------------------
  ## traitement columns info  
  #-----------------------------  

  proc sqlTypeInfo(db: PPGconn;table , field :string ) : DbType =

    var requete:string
    var ConnInfo = new(PGsql)

    requete =fmt"""SELECT atttypid as OID FROM   pg_attribute WHERE  attrelid = '"{table}"'::regclass and attname ='{field}';"""
    db.sqlQuery(ConnInfo, requete )

    return  oidType(parseInt($pqgetvalue(ConnInfo.Rslt, 0, 0)))


  ##----------- sqlColInfo/sqlQueryInfo------------

  proc sqlColInfo*(db: PPGconn; table: string ; columns: var DbColumns; )=
    var requete:string
    var Connx = new(PGsql)

    requete =fmt"""SELECT
    cl.column_name,cl.ORDINAL_POSITION,cl.DATA_TYPE,cl.CHARACTER_MAXIMUM_LENGTH,cl.NUMERIC_PRECISION,cl.NUMERIC_SCALE 
    ,(select pg_catalog.col_description(oid,cl.ordinal_position::int) from pg_catalog.pg_class c where c.relname=cl.table_name) as column_comment
    FROM information_schema.columns cl  
    WHERE cl.table_catalog='{GetDb(db)}' and cl.table_name='{table}' order by 2 ;"""
    echo requete
    Connx.Rslt = pqexec(db,requete )
    let operation : string  =fmt"{pqcmdStatus(Connx.Rslt)}"
    case operation 
      of "SELECT 0" :
        pgErrSQL(fmt"Proc sqlColInfo Error occurs : {table}")
      else : discard

    Connx.Rows = pqntuples(Connx.Rslt)
    Connx.Cols = pqnfields(Connx.Rslt)
    Connx.Rang = (pqntuples(Connx.Rslt) - 1)
    Connx.Field = (pqnfields(Connx.Rslt) - 1)

    setLen(columns, Connx.Rows)
    var c : int32  = 0
    for r in 0 ..  Connx.Rang:
      for i in 0.. Connx.Field:
        case i
          of 0: 
              columns[c].name =Connx.sqlValue(r,i)
              columns[c].tableName = table

          of 1:
              columns[c].position  = parseInt($Connx.sqlValue(r, i))

          of 2: columns[c].typ = db.sqlTypeInfo(columns[c].tableName,columns[c].name)

          of 3: 
              if Connx.sqlisNul(r, i) :
                columns[c].maxchar= 0
              else : columns[c].maxchar   = parseInt($Connx.sqlValue(r, i))

          of 4: 
              if Connx.sqlisNul(r, i) :
                columns[c].precision = 0
              else : columns[c].precision = parseInt($Connx.sqlValue(r, i))

          of 5: 
              if Connx.sqlisNul(r, i) :
                columns[c].scale = 0
              else : 
                columns[c].scale     = parseInt($Connx.sqlValue(r, i))

          of 6:
              columns[c].comment   = Connx.sqlValue(r, i)
          
          else : discard
      inc(c)


  proc sqlQueryInfo*(db: PPGconn; ConnSql : PGsql ; columns: var DbColumns; )=
    var Connx = new(PGsql)
    setLen(columns, ConnSql.Cols)
    var requete:string
    var table : string
    var c : int32  = 0
    var r : int32  = 0
    var Oidx : Oid
    
    for rang in 0.. ConnSql.Field:
      Oidx = pqftable(ConnSql.Rslt,c)
      requete =fmt"""SELECT attrelid::regclass  FROM   pg_attribute WHERE  attrelid = {Oidx} AND attname  ='{sqlName(ConnSql,rang)}';"""
      clearRslt(Connx)
      Connx.Rslt = pqexec(db,requete )

      var val : string = $pqgetvalue(Connx.Rslt, 0, 0)
      
      table =""
      for ch in items(val):
        if ch != '\"': add(table, ch)

      requete =fmt"""SELECT
      cl.column_name,cl.ORDINAL_POSITION,cl.DATA_TYPE,cl.CHARACTER_MAXIMUM_LENGTH,cl.NUMERIC_PRECISION,cl.NUMERIC_SCALE 
      ,(select pg_catalog.col_description(oid,cl.ordinal_position::int) 
            from pg_catalog.pg_class c where c.relname=cl.table_name) as column_comment
      FROM information_schema.columns cl  
      WHERE cl.table_catalog='{GetDb(db)}' and cl.table_name='{table}' and  cl.column_name='{sqlName(ConnSql,rang)}' order by 2 ;"""

      clearRslt(Connx)
      db.sqlQuery(Connx, requete )

      for i in 0..Connx.Field:
        case i 
          of 0:
              columns[c].name =Connx.sqlValue(r,i)
              columns[c].tableName = table
          of 1:
              columns[c].position  = c

          of 2:
              columns[c].typ = db.sqlTypeInfo(columns[c].tableName,columns[c].name)

          of 3: 
              if Connx.sqlisNul(r, i) :
                columns[c].maxchar= 0
              else : columns[c].maxchar   = parseInt($Connx.sqlValue(r, i))

          of 4: 
              if Connx.sqlisNul(r, i) :
                columns[c].precision = 0
              else : columns[c].precision = parseInt($Connx.sqlValue(r, i))

          of 5: 
              if Connx.sqlisNul(r, i) :
                columns[c].scale = 0
              else : 
                columns[c].scale     = parseInt($Connx.sqlValue(r, i))

          of 6:
              columns[c].comment   = Connx.sqlValue(r, i)

          else : discard
      inc(c)



## return value from var-sql to var-pgm

proc `<<`*(narg :var string; v : string )= 
  narg = v

proc `<<`*(narg :var Dcml  ; v : string ) = 
  narg := v

proc `<<`*(narg :var Zoned ; v : string ) = 
  narg := v

proc `<<`*(narg :var bool  ; v : string ) = 
  case v
    of "f" , "false" ,"n","no","off","0" : 
      narg =false 
    of "t" , "true","y","yes","on","1" :
      narg = true
    else : narg = false

proc `<<`*(narg :var int; v : string )=
  if v == "" : 
    narg = 0
  else :
    narg = parseInt(v)

proc `<<`*(narg :var float; v : string )=
  if v == "" : 
    narg = 0.0
  else :
    narg = parseFloat(v)

