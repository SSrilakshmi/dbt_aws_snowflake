select * from {{ ref('bronze_hosts') }} 

--select min(host_since) from {{ ref('bronze_hosts') }} --2015-12-26

--select distinct is_superhost from {{ ref('bronze_hosts') }}  

--select * from {{ ref('bronze_hosts') }} where response_rate = 100



/*
HOST_ID	        -- unique identifier for each host
HOST_NAME	
HOST_SINCE      -- cannot be less than 1900-01-01
IS_SUPERHOST	-- true, false
RESPONSE_RATE	-- not null
CREATED_AT
FILENAME	
FILE_ROW_NUMBER	
FILE_CONTENT_KEY	
FILE_LAST_MODIFIED	
START_SCAN_TIME
*/

