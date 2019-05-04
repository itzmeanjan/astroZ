<p align="center"><img src="/logo/logotype-horizontal.png"></p>

# astroZ

An Android App, shows Astronomy Picture of the Day, built with :heart: using Flutter.


## Documentation ::

  1. This Android App will fetch **Astronomy Picture of the Day** aka **APOD**, from an Express App, which is running on a machine in Local Network (in my case).
  
  2. You might be interested in running that Express App on Cloud or on some remote server, then make necessary changes.
  
  3. You can find Express App in this [repo](https://github.com/itzmeanjan/apod_server).
  
  4. And you will also require to store all APODs in local database.
  
  5. In my case, I used a PostgreSQL Database.
  
  6. So, create a SQL database and a table like the following.
  
  ```
    nasa_apod=# \d apod_data
                         Table "public.apod_data"
     Column      |         Type          | Collation | Nullable | Default 
-----------------+-----------------------+-----------+----------+---------
 date            | character(10)         |           | not null | 
 copyright       | text                  |           |          | 
 explanation     | text                  |           |          | 
 hdurl           | text                  |           |          | 
 media_type      | character varying(25) |           |          | 
 service_version | character varying(10) |           |          | 
 title           | text                  |           |          | 
 url             | text                  |           |          | 

  ```
  7. Then go to this [repo](https://github.com/itzmeanjan/apod_fetcher), and keep downloading all APODs, upto current date.
  
  8. Don't forget to run [apod_updater.py](https://github.com/itzmeanjan/apod_fetcher/blob/master/apod_updater.py) daily, so that you keep getting current day's APOD from NASA.
  
  9. This App lets you download APOD, if and only if it's an image.
  
  10. You might even consider to use a certain APOD as you wallpaper, which is also feasible from that App.
  
  11. This app targets *API Level 28*.
  
  12. Of course it uses material design.
  
  13. This app also displays test Ads using **Google's Mobile Ad SDK**.
  
  14. You might consider using this app's code as an example for using Ads in your app, so that you can monitize your app.
  
  15. This app also caches previously queried APOD in local SQLite database using ROOM consistency Library.
  
  16. So, when previously requested data is available in local database, it will simply use that otherwise it will perform a query to that Express App, which you may find [here](https://github.com/itzmeanjan/apod_server).
  
  
## Screenshots ::

  ![Screen Capure 1](https://github.com/itzmeanjan/astroZ/blob/master/Screenshot_20190317-122725.png)
  
  ![Screen Capure 1](https://github.com/itzmeanjan/astroZ/blob/master/Screenshot_20190317-122734.png)
  
  ![Screen Capure 1](https://github.com/itzmeanjan/astroZ/blob/master/Screenshot_20190317-122743.png)
  
  ![Screen Capure 1](https://github.com/itzmeanjan/astroZ/blob/master/Screenshot_20190317-122752.png)
  
  ![Screen Capure 1](https://github.com/itzmeanjan/astroZ/blob/master/Screenshot_20190317-122804.png)
  
  
## Screen Recoring ::

  You may like to check [this](https://github.com/itzmeanjan/astroZ/blob/master/screenRecord.mp4) screen recording out.
  
  
## Download ::

  You can download release version of this app [here](https://github.com/itzmeanjan/astroZ/blob/master/astroZ.apk) or just compile it yourself.
  Don't forget to create local database and populate it with all APODs till date, using scripts from this [repo](https://github.com/itzmeanjan/apod_fetcher). 
  Make sure you've started the Express App properly in local machine and set correct IPAddress and PortNumber. Otherwise you might see some unexpected results.
  For initial testing I'd suggest you to run Express App aka [apod_server](https://github.com/itzmeanjan/apod_server) on a machine in Local Network. And later on you might think of shifting to Cloud solutions.
  
  
## Courtesy ::

   Thanks to [Flutter](http://flutter.dev/), for building such a great UI framework, so that developers can make cool Apps easily. And :heart: for Dart Team.
   

That's all. Hope it was helpful :blush:
