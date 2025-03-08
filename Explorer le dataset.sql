/*
Cet exercice est tiré du bouquin de David Asboth : The well grounded data analyst. 
Lien vers son Github : https://github.com/davidasboth/the-well-grounded-data-analyst
dans le chapitre 2, on dispose d'un dataset avec des adresses (~100k)
le client pose deux questions : 
- est-ce que la majorité de nos clients sont à Londres ?
- est-ce qu'il y a des endroits où on sous performe ?
Le fichier fourni est un fichier plat addresses.csv. 
L'auteur utilise Jupyter Notebook pour examiner le dataset. 

Moi, je vais utiliser SQL car c'est le langage que je pratique pour le moment. 
D'autres githubs arrivent avec du py. 
Mes outils : je fais tourner sql server sur un docker et j'utilise VSC comme client (je 
teste VSC pour faire du SQL suite à l'annonce de MS de fermer Azure Database Studio). 
J'ai mis en forme le fichier avec BBEdit (que je préfère à notepad++), j'ai chargé 
le fichier sur le docker qui fait tourner sql server, puis j'ai fait un bulk insert pour créer 
la db Prowidget Systems (le nom de la company) et la table (dbo.companies)  avec laquelle je vais travailler. 
En amont, j'ai aussi un peu exploré le fichier avec SSMS et DBeaver. J'ai également 
préparer un docker avec mysql et un avec postgresql pour tester ces outils dans une 
phase ultérieure. 

La db est prête. On commence notre enquête !
*/



-- on commence par une visualisation pour vérifier que la table est bien formatée. 
-- ça l'air d'être le cas. 
SELECT *
FROM dbo.companies

-- la table a une colonne dépense, donc je jette un oeil à la somme des dépenses
SELECT COUNT(company_depense)
FROM dbo.companies

-- on voit que les adresses sont composées de plusieurs champs
-- tous les champs n'ont pas l'air d'être les mêmes dans chaque adresse 
-- je propose donc de commencer à compter les champs qui sont séparés par des ','
SELECT company_adresse, 
    LEN(company_adresse) - LEN(REPLACE(company_adresse, ',', '')) AS nbre_champs_adresse
FROM dbo.companies

-- j'ajoute une colonne avec le nombre de champs de mes adresses (séparés par des ",")
ALTER TABLE dbo.companies
ADD nbre_champs_adresse INT

UPDATE dbo.companies 
SET nbre_champs_adresse = LEN(company_adresse) - LEN(REPLACE(company_adresse, ',', '')) + 1

-- je vois que le nombre de champs qui composent les adresses varient (3, 4, 5...)
-- l'auteur avait lui aussi examiné le nombre de champs. 
-- après, nos chemins divergent. 

SELECT COUNT(*)
FROM dbo.companies
WHERE company_adresse LIKE '%LONDON%'

/*
Je pense que le dernier champ est toujours un cp
Je pense que tous les cp sont faits de deux séries alphanum
Je pense que le système est hiérarchique 
Je suis allé vérifier sur le web, et effectivement, le cp au UK 
ont une structure systématique (source wikipedia) : 
A9 9AA
A99 9AA
A9A 9AA
AA9 9AA
AA99 9AA
AA9A 9AA
    
L'auteur a adopté une apporche en termes de noms de villes. 
Je ne suis pas convaincu. D'autant qu'il se retrouve avec beaucoup d'adresses "others"
avec cette apporche. 

=> je vais travailler sur la base des cp
=> je vais mettre mes cp dans une colonne
=> je vais vérifier la structure de mes cp... on va avoir quelques surprises... 
*/

ALTER TABLE dbo.companies
ADD cp NVARCHAR(12)

SELECT company_adresse, CHARINDEX(',', REVERSE(company_adresse), 1), LEN(company_adresse) - CHARINDEX(',', REVERSE(company_adresse), 1)
FROM dbo.companies

SELECT company_id, company_adresse, LEN(REVERSE(SUBSTRING(REVERSE(company_adresse), 1, CHARINDEX(',', REVERSE(company_adresse), 1)-2))) AS code_postal
FROM dbo.companies

-- y en a aux Etats-Unis... du coup mon NVARCHAR n'est pas assez long
-- y en a aux Emirats Arabes Unis => je vais les delete. Y en a 8. et 12 des CAYMAN ISLAND
-- y en a 1 qui a royaume uni comme cp.... 
    
UPDATE dbo.companies
SET cp = REVERSE(SUBSTRING(REVERSE(company_adresse), 1, CHARINDEX(',', REVERSE(company_adresse), 1)-2))

ALTER TABLE dbo.companies
ALTER COLUMN cp NVARCHAR(14)

SELECT *
FROM dbo.companies
WHERE company_adresse LIKE '%ARAB%'

SELECT *
FROM dbo.companies
WHERE company_adresse LIKE '%UNITED STATES%'

SELECT *
FROM dbo.companies
WHERE company_adresse LIKE '%CAYMAN ISLAND%'

SELECT *
FROM dbo.companies
WHERE company_adresse LIKE '%KITTS%'

DELETE FROM dbo.companies
WHERE company_adresse LIKE '%ARAB%'

DELETE FROM dbo.companies
WHERE company_adresse LIKE '%CAYMAN ISLAND%'

DELETE FROM dbo.companies
WHERE company_id LIKE 1101 -- OR 62218 OR 73212

-- j'ai des adresses quasi vides (9). Dont à Potter Street 
DELETE FROM dbo.companies
WHERE LEN(company_adresse) < 20

-- ici il me reste des 'cp' trop longs... genre encore des US, des Saint-Vincent les grenadines....  
-- un vrai cp c'est max 8 suivant la nomenclature UK. 

DELETE FROM dbo.companies
WHERE LEN(SUBSTRING(REVERSE(company_adresse), 1, CHARINDEX(',', REVERSE(company_adresse), 1)-2)) > 8

-- ça fait 216 lignes supprimées
-- la ligne ci-dessous fonctionne maintenant !
UPDATE dbo.companies
SET cp = REVERSE(SUBSTRING(REVERSE(company_adresse), 1, CHARINDEX(',', REVERSE(company_adresse), 1)-2))
-- 

SELECT *
FROM dbo.companies
ORDER BY cp ASC

-- ici j'ai encore quelques lignes à nettoyer avec des cp qui commencent par des chiffres. 62 lignes. 

SELECT *
FROM dbo.companies
WHERE PATINDEX('[0-9]%',cp) = 1

DELETE FROM dbo.companies
WHERE PATINDEX('[0-9]%',cp) = 1
-- 60 lignes affectées
DELETE FROM dbo.companies
WHERE cp LIKE '%Zimbabwe%'
DELETE FROM dbo.companies
WHERE cp LIKE '%Surrey%'
DELETE FROM dbo.companies
WHERE cp LIKE '%Zimbabwe%'

SELECT *
FROM dbo.companies
ORDER BY cp ASC

SELECT *
FROM dbo.companies
WHERE cp LIKE '% SL3%'
ORDER BY cp ASC

UPDATE dbo.companies
SET cp = 'SL3 8QF'
WHERE cp LIKE ' SL3%'

SELECT *
FROM dbo.companies
ORDER BY cp ASC

SELECT COUNT(*)
FROM dbo.companies
    
-- il me reste 97813 entrées sur 100.001 entrées => 97,8% OK 

SELECT company_adresse, cp, PATINDEX('%[0-9]%', cp)
FROM dbo.companies
ORDER BY PATINDEX('%[0-9]%', cp) ASC
-- avec DESC si mon PATINDEX est plus grand que 3 c'est encore bizarre
-- avec ASC j'ai des PATINDEX 0.... on supprime aussi. 

DELETE FROM dbo.companies
WHERE PATINDEX('%[0-9]%', cp) > 3

DELETE FROM dbo.companies
WHERE PATINDEX('%[0-9]%', cp) = 0
-- 289 lignes affectées

-- ça y est, je n'ai plus que des cp UK ! 
-- wikipedia me dit que la ou les 2 première(s) lettre(s) représente(nt)
-- je vais les extraire dans une colonne et puis faire une table d'équivalence avec
-- le nom des zones
SELECT cp, SUBSTRING(cp, 1, PATINDEX('%[0-9]%', cp)-1)
FROM dbo.companies

ALTER TABLE dbo.companies
ADD lettres_zone NVARCHAR(2)

SELECT *
FROM dbo.companies

UPDATE dbo.companies
SET lettres_zone = SUBSTRING(cp, 1, PATINDEX('%[0-9]%', cp)-1)


SELECT *
FROM dbo.companies

SELECT lettres_zone, SUM(company_depense)
FROM dbo.companies
GROUP BY lettres_zone
ORDER BY lettres_zone ASC

ALTER TABLE dbo.companies
ADD zone NVARCHAR(30)

SELECT *
FROM dbo.companies

-- j'ai demandé à Perplexity de me faire une table de conversion
UPDATE dbo.companies
SET zone =
       CASE 
           WHEN lettres_zone LIKE 'AB%' THEN 'Aberdeen'
           WHEN lettres_zone LIKE 'AL%' THEN 'St Albans'
           WHEN lettres_zone LIKE 'B%' THEN 'Birmingham'
           WHEN lettres_zone LIKE 'BA%' THEN 'Bath'
           WHEN lettres_zone LIKE 'BB%' THEN 'Blackburn'
           WHEN lettres_zone LIKE 'BD%' THEN 'Bradford'
           WHEN lettres_zone LIKE 'BH%' THEN 'Bournemouth'
           WHEN lettres_zone LIKE 'BL%' THEN 'Bolton'
           WHEN lettres_zone LIKE 'BN%' THEN 'Brighton'
           WHEN lettres_zone LIKE 'BR%' THEN 'Bromley'
           WHEN lettres_zone LIKE 'BS%' THEN 'Bristol'
           WHEN lettres_zone LIKE 'BT%' THEN 'Belfast'
           WHEN lettres_zone LIKE 'CA%' THEN 'Carlisle'
           WHEN lettres_zone LIKE 'CB%' THEN 'Cambridge'
           WHEN lettres_zone LIKE 'CF%' THEN 'Cardiff'
           WHEN lettres_zone LIKE 'CH%' THEN 'Chester'
           WHEN lettres_zone LIKE 'CM%' THEN 'Chelmsford'
           WHEN lettres_zone LIKE 'CO%' THEN 'Colchester'
           WHEN lettres_zone LIKE 'CR%' THEN 'Croydon'
           WHEN lettres_zone LIKE 'CT%' THEN 'Canterbury'
           WHEN lettres_zone LIKE 'CV%' THEN 'Coventry'
           WHEN lettres_zone LIKE 'CW%' THEN 'Crewe'
           WHEN lettres_zone LIKE 'DA%' THEN 'Dartford'
           WHEN lettres_zone LIKE 'DD%' THEN 'Dundee'
           WHEN lettres_zone LIKE 'DE%' THEN 'Derby'
           WHEN lettres_zone LIKE 'DG%' THEN 'Dumfries'
           WHEN lettres_zone LIKE 'DH%' THEN 'Durham'
           WHEN lettres_zone LIKE 'DL%' THEN 'Darlington'
           WHEN lettres_zone LIKE 'DN%' THEN 'Doncaster'
           WHEN lettres_zone LIKE 'DT%' THEN 'Dorchester'
           WHEN lettres_zone LIKE 'DY%' THEN 'Dudley'
           WHEN lettres_zone LIKE 'E%' THEN 'Londres'
           WHEN lettres_zone LIKE 'EC%' THEN 'Londres'
           WHEN lettres_zone LIKE 'EH%' THEN 'Édimbourg'
           WHEN lettres_zone LIKE 'EN%' THEN 'Enfield'
           WHEN lettres_zone LIKE 'EX%' THEN 'Exeter'
           WHEN lettres_zone LIKE 'FK%' THEN 'Falkirk'
           WHEN lettres_zone LIKE 'FY%' THEN 'Blackpool'
           WHEN lettres_zone LIKE 'G%' THEN 'Glasgow'
           WHEN lettres_zone LIKE 'GL%' THEN 'Gloucester'
           WHEN lettres_zone LIKE 'GU%' THEN 'Guildford'
           WHEN lettres_zone LIKE 'HA%' THEN 'Harrow'
           WHEN lettres_zone LIKE 'HD%' THEN 'Huddersfield'
           WHEN lettres_zone LIKE 'HG%' THEN 'Harrogate'
           WHEN lettres_zone LIKE 'HP%' THEN 'Hemel Hempstead'
           WHEN lettres_zone LIKE 'HR%' THEN 'Hereford'
           WHEN lettres_zone LIKE 'HS%' THEN 'Hébrides extérieures'
           WHEN lettres_zone LIKE 'HU%' THEN 'Kingston-upon-Hull'
           WHEN lettres_zone LIKE 'HX%' THEN 'Halifax'
           WHEN lettres_zone LIKE 'IG%' THEN 'Ilford'
           WHEN lettres_zone LIKE 'IP%' THEN 'Ipswich'
           WHEN lettres_zone LIKE 'IV%' THEN 'Inverness'
           WHEN lettres_zone LIKE 'KA%' THEN 'Kilmarnock'
           WHEN lettres_zone LIKE 'KT%' THEN 'Kingston upon Thames'
           WHEN lettres_zone LIKE 'KW%' THEN 'Kirkwall'
           WHEN lettres_zone LIKE 'KY%' THEN 'Kirkcaldy'
           WHEN lettres_zone LIKE 'L%' THEN 'Liverpool'
           WHEN lettres_zone LIKE 'LA%' THEN 'Lancaster'
           WHEN lettres_zone LIKE 'LD%' THEN 'Llandrindod Wells'
           WHEN lettres_zone LIKE 'LE%' THEN 'Leicester'
           WHEN lettres_zone LIKE 'LL%' THEN 'Llandudno'
           WHEN lettres_zone LIKE 'LN%' THEN 'Lincoln'
           WHEN lettres_zone LIKE 'LS%' THEN 'Leeds'
           WHEN lettres_zone LIKE 'LU%' THEN 'Luton'
           WHEN lettres_zone LIKE 'M%' THEN 'Manchester'
           WHEN lettres_zone LIKE 'ME%' THEN 'Rochester'
           WHEN lettres_zone LIKE 'MK%' THEN 'Milton Keynes'
           WHEN lettres_zone LIKE 'ML%' THEN 'Motherwell'
           WHEN lettres_zone LIKE 'N%' THEN 'Londres'
           WHEN lettres_zone LIKE 'NE%' THEN 'Newcastle upon Tyne'
           WHEN lettres_zone LIKE 'NG%' THEN 'Nottingham'
           WHEN lettres_zone LIKE 'NN%' THEN 'Northampton'
           WHEN lettres_zone LIKE 'NP%' THEN 'Newport'
           WHEN lettres_zone LIKE 'NR%' THEN 'Norwich'
           WHEN lettres_zone LIKE 'NW%' THEN 'Londres'
           WHEN lettres_zone LIKE 'OL%' THEN 'Oldham'
           WHEN lettres_zone LIKE 'OX%' THEN 'Oxford'
           WHEN lettres_zone LIKE 'PA%' THEN 'Paisley'
           WHEN lettres_zone LIKE 'PE%' THEN 'Peterborough'
           WHEN lettres_zone LIKE 'PH%' THEN 'Perth'
           WHEN lettres_zone LIKE 'PL%' THEN 'Plymouth'
           WHEN lettres_zone LIKE 'PO%' THEN 'Portsmouth'
           WHEN lettres_zone LIKE 'PR%' THEN 'Preston'
           WHEN lettres_zone LIKE 'RG%' THEN 'Reading'
           WHEN lettres_zone LIKE 'RH%' THEN 'Redhill'
           WHEN lettres_zone LIKE 'RM%' THEN 'Romford'
           WHEN lettres_zone LIKE 'S%' THEN 'Sheffield'
           WHEN lettres_zone LIKE 'SA%' THEN 'Swansea'
           WHEN lettres_zone LIKE 'SE%' THEN 'Londres'
           WHEN lettres_zone LIKE 'SG%' THEN 'Stevenage'
           WHEN lettres_zone LIKE 'SK%' THEN 'Stockport'
           WHEN lettres_zone LIKE 'SL%' THEN 'Slough'
           WHEN lettres_zone LIKE 'SM%' THEN 'Sutton'
           WHEN lettres_zone LIKE 'SN%' THEN 'Swindon'
           WHEN lettres_zone LIKE 'SO%' THEN 'Southampton'
           WHEN lettres_zone LIKE 'SP%' THEN 'Salisbury'
           WHEN lettres_zone LIKE 'SR%' THEN 'Sunderland'
           WHEN lettres_zone LIKE 'SS%' THEN 'Southend-on-Sea'
           WHEN lettres_zone LIKE 'ST%' THEN 'Stoke-on-Trent'
           WHEN lettres_zone LIKE 'SW%' THEN 'Londres'
           WHEN lettres_zone LIKE 'SY%' THEN 'Shrewsbury'
           WHEN lettres_zone LIKE 'TA%' THEN 'Taunton'
           WHEN lettres_zone LIKE 'TD%' THEN 'Galashiels'
           WHEN lettres_zone LIKE 'TF%' THEN 'Telford'
           WHEN lettres_zone LIKE 'TN%' THEN 'Tonbridge'
           WHEN lettres_zone LIKE 'TQ%' THEN 'Torquay'
           WHEN lettres_zone LIKE 'TR%' THEN 'Truro'
           WHEN lettres_zone LIKE 'TS%' THEN 'Cleveland'
           WHEN lettres_zone LIKE 'TW%' THEN 'Twickenham'
           WHEN lettres_zone LIKE 'UB%' THEN 'Southall'
           WHEN lettres_zone LIKE 'W%' THEN 'Londres'
           WHEN lettres_zone LIKE 'WA%' THEN 'Warrington'
           WHEN lettres_zone LIKE 'WC%' THEN 'Londres'
           WHEN lettres_zone LIKE 'WD%' THEN 'Watford'
           WHEN lettres_zone LIKE 'WF%' THEN 'Wakefield'
           WHEN lettres_zone LIKE 'WN%' THEN 'Wigan'
           WHEN lettres_zone LIKE 'WR%' THEN 'Worcester'
           WHEN lettres_zone LIKE 'WS%' THEN 'Walsall'
           WHEN lettres_zone LIKE 'WV%' THEN 'Wolverhampton'
           WHEN lettres_zone LIKE 'YO%' THEN 'York'
           WHEN lettres_zone LIKE 'ZE%' THEN 'Lerwick'
           ELSE 'Inconnu'
       END 
FROM dbo.companies


SELECT *
FROM dbo.companies

-- YEAAAAAAH !!
SELECT zone, SUM(company_depense)
FROM dbo.companies
GROUP BY zone
ORDER BY SUM(company_depense) DESC

/*
Je copie les donénes dans un excel. 
Je peux sortir un grpahique en histogramme.
On voit que London est largement plus représentée.
On voit que Shefield est très représentée : pourquoi ?

Pour aller plus loin : 
- ajouter des attributs (colonnes) : population, revenu médian,... ou autre info pertinente pour déterminer 
si certaines zones sont à privilégier dans la stratégie de développement et sortir des infos
relatives et plus absolues ;
- sortir une carte du UK avec les infos ;
- chnager de granularité en explorant la sjuite des cp ;
- ...





