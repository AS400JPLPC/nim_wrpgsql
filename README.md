# nim_wrpgsql

***wrapper postgresql basé sur libpq de Nim pour la gestion***

Bonjour, je me suis appuyé sur les sources déposés dans github **NIM ** orm et divers exemples misent à disposition [https://github.com/search?q=nim+orm](URL)

# ** Les principes généraux de gestion pour l'entreprise.
**La fonction TRY est mise fortement à l'épreuve**

# ** Tout est en test  mais déjà fonctionnel  
avec une base de donnée mise à disposition [https://www.postgresqltutorial.com/postgresql-sample-database/](URL)  

*<u>dans l'exemple j'ai remis d'aplomb les script pour postgresql</u>*



- **VARIABLE** :

 X Actif
 
 0 *Encours de développement*

 - X__ String
 - X__ Zoned fixed String
 - X__ Dcml fixed Numéric
 - X__ Date fixed YYYY-MM-DD
 - X__ Time fixed HH:MM:SS
 - X__ Int
 - X__ Float
 - X__ Bool

 - **Différentes façons de faire sont dans les exemples pour récupérer les valeurs des variables**
 - **possibilité de récupérer les informations sur les colonnes**
	 - name
	 - table
	 - type
	 - nullable
	 - position
	 - maximum char
	 - précision
	 - scale
	 - commentaire
	 
- **des fonctions traditionnelles**

	QUERY / PAGE / FIRST / LAST / NEXT / PRIOR / LOCK
	
	BEGIN / COMMIT / ROLLBACK
	
	SAVEPOINT / SAVEPOINTROLLBACK  /  SAVEPOINTRELEASE
	
	Connect
	
	closeDb
	
	clearRslt
	
	GetDb
	
	GetUser
	
	GetPassword
	
	GetHost
	
	GetPort
	
	isTable
	
	sqlValue
	
	sqlName
	
	sqlNumber
	
	sqlisNul
	
	sqlLen
	
	sqlType
	
	sqlColInfo
	
	sqlQueryInfo
	
	fld... from SQL 
	
    sql... to SQL

ex:

      for r in  0 .. Conn.Rang :
    	Rcd.vkey.fld(Conn,r, 0)
    	Rcd.vtext.fld(Conn,r, 1)


ex:

>     try:
    	requete =fmt"UPDATE tabletype SET vtextx='totsxxxx' WHERE vkey = 10100 ;"
    	DbProd.sqlQuery(ConnProd, requete )
    except NOTFOUND :
    	echo  "NOT FOUND :" , getCurrentExceptionMsg()
    except ERRSQL :
    	echo  "ERR SQL :" , getCurrentExceptionMsg()

ex:  
>         proc sql*(a: Date): string =  
          if a.Data.format("yyyy-MM-dd") == "0001-01-01" and a.isBool == true : return "null"  
          else :
            var d : string = a.Data.format("yyyy-MM-dd")
          return fmt"'{d}'"
        proc sql*(a: Temps): string =
          if a.Data.format("HH:mm:ss") == "00:00:00" and a.isBool == true : return "null"
          else :
            var h : string = a.Data.format("HH:mm:ss")
          return fmt"'{h}'"  


PS:
> je vais aussi regarder du coté des blod  

-   la fonction **fmt** de nim est suffisante pour mettre en forme les ordres SQL dynamiquement  

-   les procédures "sql" pour les Zoned/Dcml/Date/Temps peuvent être null et très pratique pour formaté les zones dans les requettes SQL.  

  

-   Des exemples simple et fonctionnel   
j'ai prix une table type et une table basé sur le model OS400 DB2 ou tout est en majuscule DDS  

&nbsp;
&nbsp;

*<u>exemple mise à jour de la tabletype</u>*
>  
 
var lock : bool =  true  

while lock == true :  
    
    try :  
      DbProd.Begin
      #requete =fmt"SELECT * FROM tabletype  WHERE vkey = 101000 ;" 
      #requete =fmt"SELECT * FROM tabletype  WHERE vkeyazertyuiop = 101 ;" 
      requete =fmt"SELECT * FROM tabletype  WHERE vkey = 101 ;" 
      DbProd.sqlLock(ConnProd, requete )  
      ....
      requete =fmt"DELETE FROM tabletype   WHERE vkey = 101 ;" 
      DbProd.sqlQuery(ConnProd, requete )
      DbProd.Commit
      DbProd.Begin

      Rcd.vdate:="2020-10-20"
      # Rcd.vdate:="0001-01-01"
      requete =fmt"""INSERT INTO tabletype
      (vdate, vnumeric, vtext, vonchar, vheure, vkey, vbool, vchar)
      VALUES({Rcd.vdate.sql()},5000.00, 'JPL', 'C', '11:10:01', 101, true, 'jp-Laroche');""" 

      DbProd.sqlQuery(ConnProd, requete)  
      
      # pour le test lock en concurrence 
      echo "pause : 234"
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
