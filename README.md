# nim_wrpgsql

***wrapper postgresql basé sur libpq de Nim pour la gestion***

Bonjour, je me suis appuyé sur les sources déposés dans github nim orm et divers exemples misent à disposition

# ** Les principes généraux de gestion pour l'entreprise.
**La fonction TRY est mise fortement à l'épreuve**


 - **VARIABLE** :

 X Actif
 0 *Encours de développement*
 - X__ String
 - X__ Zoned fixed String
 - X__ Dcml fixed Numéric
 - O__ Date fixed YYYY-MM-DD
 - O__ Time fixed HH:MM:SS
 - X__ Int
 - X__ Float
 - X__Bool

 - **Différentes façons de faire sont dans les exemples pour récupérer les valeurs des variables**
 - **possibilité de récupérer les informations sur les colonnes**
	 - name
	 - table
	 - type
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
<<

ex:

      for r in  0 .. Conn.Rang :
    	Rcd.vkey<<Conn.sqlValue(r, 0)
    	Rcd.vtext<<Conn.sqlValue(r, 1)


ex:

    try:
    	requete =fmt"UPDATE tabletype SET vtextx='totsxxxx' WHERE vkey = 10100 ;"
    	DbProd.sqlQuery(ConnProd, requete )
    except NOTFOUND :
    	echo  "NOT FOUND :" , getCurrentExceptionMsg()
    except ERRSQL :
    	echo  "ERR SQL :" , getCurrentExceptionMsg()

PS:

> Je mettrais à disposition toutes les expliquations dès que les variables Date et Times seront incluses
> je vais aussi regarder du coté des blod

> la fonction **fmt** de nim est suffisante pour mettre en forme les ordres SQL dynamiquement  
