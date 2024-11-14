Hello cher lecteur !

Petit récap des étapes de mon travail :

1/ init.sql
    - Création DB 
    - Connection Stage S3 bucket AWS
    - Création file_format CSV
    - Création des tables selon le schémas
    - Modif colonnes dans la table "Album"
    - Intégration des données .csv dans les tables 
    - Gestion du cas de la table "Tracks" 

2/ star.sql 
    - Table des faits : Tracks 
    - Schémas :
        Track  -> Album -> Artist 
               -> Genre 
               -> MediaType
               -> Playlist -> PlaylistTrack
        Tout est relié à Track, central.

3/ query.sql 
    - Création d'une table provisoire pour stocker les query et leur résultats
    - Création des requêtes SQL
    - Ajout de la fonction "insert into <temp_results>" et modifs SELECT
    - Création du format .txt
    - Création du stage sanou_stage
    - Copy de la table Temp_Results dans @sanou_stage/answer.txt
    - Téléchargement du fichier sur l'interface SnowFlake (dans l'archive)

Vous avez toutes les clefs !