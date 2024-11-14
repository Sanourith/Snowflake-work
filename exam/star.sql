-- star_schema
DROP SCHEMA IF EXISTS Star_schema;
CREATE SCHEMA IF NOT EXISTS Star_schema;
USE SCHEMA Star_schema;

-- Pour mon schéma en étoile, je choisi la table de fait : Track, centrale dans l'analyse et simplification des requêtes sur les chansons.
-- Je la joins à Album, Genre, MediaType, Playlist, 
-- Je relie ensuite à Album <-> Artist et Playlist <-> PlaylistTrack

-- DROP TABLE Star_Schema.New_tracks;
CREATE TABLE Star_Schema.New_tracks (
"TrackId" NUMBER, 
"TrackName" VARCHAR(255), 
"Composer" VARCHAR(255), 
"TrackTime" NUMBER, 
"Memory (B)" NUMBER, 
"UnitPrice" DECIMAL(10, 2),
"AlbumId" NUMBER, 
"AlbumTitle" VARCHAR(255), 
"ProductionYear" NUMBER, 
"CD_number" NUMBER,
"ArtistId" NUMBER, 
"ArtistName" VARCHAR(255), 
"Birthyear" NUMBER, 
"Country" VARCHAR(255),
"GenreId" NUMBER, 
"GenreName" VARCHAR(255), 
"MediaTypeId" NUMBER, 
"MediaTypeName" VARCHAR(255), 
"PlaylistId" NUMBER, 
"PlayListName" VARCHAR(255)
)

insert all
into STAR_SCHEMA.New_Tracks ("TrackId", "TrackName", "Composer", "TrackTime", "Memory (B)", "UnitPrice",
                             "AlbumId", "AlbumTitle", "ProductionYear", "CD_number",
                             "ArtistId", "ArtistName", "Birthyear", "Country",
                             "GenreId", "GenreName", "MediaTypeId", "MediaTypeName", "PlaylistId", "PlayListName")
SELECT 
    t."TrackId" AS "TrackId",
    t."Title" AS "TrackName",
    t."Composer" AS "Composer",
    t."Milliseconds" AS "TrackTime",
    t."Bytes" AS "Memory (B)",
    t."UnitPrice" AS "UnitPrice",
    alb."AlbumId" AS "AlbumId",
    alb."Title" AS "AlbumTitle",
    alb."ProductionYear" AS "ProductionYear",
    alb."CD_number" AS "CD_number",
    art."ArtistId" AS "ArtistId",
    art."Name" AS "ArtistName",
    art."Birthyear" AS "Birthyear",
    art."Country" AS "Country",
    gen."GenreId" AS "GenreId",
    gen."Name" AS "GenreName",
    med."MediaTypeId" AS "MediaTypeId",
    med."Name" AS "MediaTypeName",
    pl."PlaylistId" AS "PlaylistId",
    pl."Name" AS "PlayListName"   
FROM PUBLIC.Track AS t
LEFT JOIN PUBLIC.Album AS alb ON t."AlbumId" = alb."AlbumId" 
LEFT JOIN PUBLIC.Artist AS art ON alb."ArtistId" = art."ArtistId" 
LEFT JOIN PUBLIC.Genre AS gen ON t."GenreId" = gen."GenreId" 
LEFT JOIN PUBLIC.MediaType AS med ON t."MediaTypeId" = med."MediaTypeId"
LEFT JOIN PUBLIC.PlaylistTrack AS plt ON t."TrackId" = plt."TrackId" 
LEFT JOIN PUBLIC.Playlist AS pl ON plt."PlaylistId" = pl."PlaylistId";