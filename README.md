# nasa_apod

A simple flutter application to display NASA APOD.


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
  
## Courtesy ::

   Thanks to [Flutter](http://flutter.dev/), for building such a great UI framework, so that developers can make cool Apps easily. And :heart: for Dart Team.
   

That's all. Hope it was helpful :blush:
