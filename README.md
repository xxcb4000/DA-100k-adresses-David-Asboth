David Asborth - chapter 2 => the sql way !

Cet exercice est tiré du bouquin de David Asboth : The well grounded data analyst. 
 Lien vers son Github : https://github.com/davidasboth/the-well-grounded-data-analyst
 Dans le chapitre 2, on dispose d'un dataset avec des adresses (~100k)
 le client pose deux questions : 
 - est-ce que la majorité de nos clients sont à Londres ?
 - est-ce qu'il y a des endroits où on sous performe ?
 Le fichier fourni est un fichier plat addresses.csv. 
 L'auteur utilise Jupyter Notebook pour examiner le dataset. 
 
 Moi, je vais utiliser SQL car c'est le langage que je pratique pour le moment. 
 D'autres githubs arrivent avec du py. 
 Mes outils : je fais tourner sql server sur un docker et j'utilise VSC comme client (je 
 teste VSC pour faire du SQL). 
 J'ai mis en forme le fichier avec BBEdit (que je préfère à notepad++), j'ai chargé 
 le fichier sur le docker qui fait tourner sql server, puis j'ai fait un bulk insert pour créer 
 la db Prowidget Systems (le nom de la company) et la table (dbo.companies)  avec laquelle je vais travailler. 
 En amont, j'ai aussi un peu exploré le fichier avec SSMS et DBeaver. J'ai également 
 préparer un docker avec mysql et un avec postgresql pour tester ces outils dans une 
 phase ultérieure. 
 
 La db est prête. On commence notre enquête !
