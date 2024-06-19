[![Downloads](https://img.shields.io/github/downloads/SecretFox/StreamerStats/total?style=for-the-badge)](https://github.com/SecretFox/StreamerStats/releases)  

# StreamerStats
Secret World Legend mod for adding customizeable character info box.  
![kuva](https://github.com/SecretFox/StreamerStats/assets/25548149/5b7d5629-2967-47b6-824e-d264c8983e0b)



### Customizing  
While in GUI-Edit mode:  
Mouse scroll to change size  
Right click to enable/disable background  

Use `/option StreamerStats_DisplayString "value"` to customize the box contents.  
Default is `/option StreamerStats_DisplayString "Name: %name%\\nIP: %ip%\\nPlayed: %played0%"`  
To add new lines add `\\n`

## DisplayString Templates  
`%name%` - 	characters name  
`%first%` - 	characters first name  
`%last%` - 	characters last name  
`%ip%` 		characters IP  
`%maxip%` 	characters highest reached IP  
`%played0%` hh:mm:ss formatted /played  
`%played1%` hh:mm formatted /played  
`%played2%` hh formatted /played  
`%played3%` `1d 2h` or `05h 32m` formatted /played  
`%fps0%` fps with two decimals  
`%fps1%` fps with no decimals  
`%latency0%` latency in ms  
`%latency1%` latency in seconds, 3 decimals  
`%latency2%` latency in seconds, 2 decimals  
`%x%` x coordinate  
`%y%` y coordinate  
`%z%` z coordinate  

### Installing StreamerStats  
Extract StreamerStats-v0.1.0.zip to `Secret World Legends\Data\Gui\Custom\Flash\`  
