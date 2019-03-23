package com.example.itzmeanjan.nasa_apod

import androidx.room.*

@Entity(tableName = "apod_data")
data class APODData( // data model, which gets stored into database and retrieved back, when requested
        @PrimaryKey var date: String, // compulsory one
        @ColumnInfo(name = "copyright") var copyright: String, // APOD's copyright
        @ColumnInfo(name = "explanation") var explanation: String, // explanation holds detailed description regrading APOD
        @ColumnInfo(name = "hdurl") var hdUrl: String, // url to HD version of APOD
        @ColumnInfo(name = "media_type") var mediaType: String, // whether image or something else
        @ColumnInfo(name = "title") var title: String, // title of APOD
        @ColumnInfo(name = "url") var url: String // main url, pointing to image/ video of APOD
)

@Dao
interface APODDao {
    // this interface's methods are used as helper methods for accessing local sql database
    @Insert
    fun insertAll(vararg data: APODData) // insert records into database, as it takes variable number of arguments,
    // it doesn't how many number of arguments you pass through it for storing into database

    @Delete
    fun delete(data: APODData) // deletes a specified record from database

    @Query("select * from apod_data order by date desc")
    fun getAll(): List<APODData> // get a list of all the records present in database,
    // where records are ordered in descending fashion in terms of date field

    @Query("select * from apod_data where date=:date")
    fun getByDate(date: String): APODData // fetches a specific record by date, if present
}

@Database(entities = [APODData::class], version = 1)
abstract class APODDatabase : RoomDatabase() {
    abstract fun getAPODDao(): APODDao // gives a reference to APODDao interface which will eventually
    // help us to perform various operations on database
}
