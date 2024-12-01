-- STAR SCHEMA SETUP
-- Drop and recreate the schema for the star schema model
DROP SCHEMA IF EXISTS Star_schema;
CREATE SCHEMA IF NOT EXISTS Star_schema;
USE SCHEMA Star_schema;

-- For my star schema, I am selecting the fact table: Track, which is central to my analysis and simplifies querying about songs.
-- I will join it to the Album, Genre, MediaType, and Playlist tables.
-- I will also link Album <-> Artist and Playlist <-> PlaylistTrack.

-- CREATE FACT TABLE: New_Tracks
-- Drop the table if it already exists and create a new fact table
-- This table will centralize key information on tracks, including album, artist, genre, media type, and playlist details
CREATE TABLE Star_Schema.New_tracks (
    "TrackId" NUMBER,               -- Track unique identifier
    "TrackName" VARCHAR(255),       -- Track name
    "Composer" VARCHAR(255),        -- Composer of the track
    "TrackTime" NUMBER,             -- Duration of the track in milliseconds
    "Memory (B)" NUMBER,            -- Memory size of the track in bytes
    "UnitPrice" DECIMAL(10, 2),     -- Price per track unit
    "AlbumId" NUMBER,               -- Album unique identifier
    "AlbumTitle" VARCHAR(255),      -- Album title
    "ProductionYear" NUMBER,        -- Year the album was produced
    "CD_number" NUMBER,             -- Number of CDs in the album
    "ArtistId" NUMBER,              -- Artist unique identifier
    "ArtistName" VARCHAR(255),      -- Name of the artist
    "Birthyear" NUMBER,             -- Birth year of the artist
    "Country" VARCHAR(255),         -- Country of the artist
    "GenreId" NUMBER,               -- Genre unique identifier
    "GenreName" VARCHAR(255),       -- Name of the genre
    "MediaTypeId" NUMBER,           -- Media type unique identifier
    "MediaTypeName" VARCHAR(255),   -- Media type name
    "PlaylistId" NUMBER,            -- Playlist unique identifier
    "PlayListName" VARCHAR(255),    -- Playlist name
    -- "inserted_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Populate the New_Tracks table with data from various related tables
-- Using LEFT JOINs to include track details along with album, artist, genre, media type, and playlist information
INSERT ALL
INTO STAR_SCHEMA.New_Tracks ("TrackId", "TrackName", "Composer", "TrackTime", "Memory (B)", "UnitPrice",
                             "AlbumId", "AlbumTitle", "ProductionYear", "CD_number",
                             "ArtistId", "ArtistName", "Birthyear", "Country",
                             "GenreId", "GenreName", "MediaTypeId", "MediaTypeName", "PlaylistId", "PlayListName")
SELECT 
    t."TrackId" AS "TrackId",                     -- Track ID from Track table
    t."Title" AS "TrackName",                     -- Track name
    t."Composer" AS "Composer",                   -- Composer of the track
    t."Milliseconds" AS "TrackTime",              -- Track duration in milliseconds
    t."Bytes" AS "Memory (B)",                    -- Track size in bytes
    t."UnitPrice" AS "UnitPrice",                 -- Price per track
    alb."AlbumId" AS "AlbumId",                   -- Album ID from Album table
    alb."Title" AS "AlbumTitle",                  -- Album title
    alb."ProductionYear" AS "ProductionYear",     -- Album production year
    alb."CD_number" AS "CD_number",               -- CD number in the album
    art."ArtistId" AS "ArtistId",                 -- Artist ID from Artist table
    art."Name" AS "ArtistName",                   -- Artist name
    art."Birthyear" AS "Birthyear",               -- Artist birth year
    art."Country" AS "Country",                   -- Artist's country
    gen."GenreId" AS "GenreId",                   -- Genre ID from Genre table
    gen."Name" AS "GenreName",                    -- Genre name
    med."MediaTypeId" AS "MediaTypeId",           -- Media type ID from MediaType table
    med."Name" AS "MediaTypeName",                -- Media type name
    pl."PlaylistId" AS "PlaylistId",              -- Playlist ID from Playlist table
    pl."Name" AS "PlayListName"                   -- Playlist name
FROM PUBLIC.Track AS t
LEFT JOIN PUBLIC.Album AS alb ON t."AlbumId" = alb."AlbumId"                -- Join Track with Album on Album ID
LEFT JOIN PUBLIC.Artist AS art ON alb."ArtistId" = art."ArtistId"           -- Join Album with Artist on Artist ID
LEFT JOIN PUBLIC.Genre AS gen ON t."GenreId" = gen."GenreId"                -- Join Track with Genre on Genre ID
LEFT JOIN PUBLIC.MediaType AS med ON t."MediaTypeId" = med."MediaTypeId"    -- Join Track with MediaType on MediaType ID
LEFT JOIN PUBLIC.PlaylistTrack AS plt ON t."TrackId" = plt."TrackId"        -- Join Track with PlaylistTrack on Track ID
LEFT JOIN PUBLIC.Playlist AS pl ON plt."PlaylistId" = pl."PlaylistId";      -- Join PlaylistTrack with Playlist on Playlist ID



-- Si on veut merge 2 tables 
-- Table + table_staging

-- MERGE INTO data.table AS target
-- USING data.table_staging AS source
-- ON target.id = source.id 
-- WHEN MATCHED THEN
--     UPDATE SET
    -- toutes les colonnes = source.colonnes



-- ensuite on troncate la staging pour vider les données après merge.