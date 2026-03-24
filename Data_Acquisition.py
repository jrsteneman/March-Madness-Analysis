import pandas as pd
import requests

url = 'https://kenpom.com/'
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": "https://www.google.com/",
    "Connection": "keep-alive",
}

session = requests.Session()
response = session.get(url, headers=headers)

print(response.status_code)

dfs = pd.read_html(response.text)
session.close()
print(len(dfs))
df = dfs[0]

#Extract desired columbs

stats = df.iloc[:,[1,5,7,9,13]]

stats.columns = ['Team','ORtg','DRtg','AdjT','NetRtg']

#Remove seed numbers, spaces and NAs

for i in range(10):
    stats.loc[:,'Team'] = stats['Team'].str.replace(str(i),'') 

stats.loc[:,'Team'] = stats['Team'].str.rstrip()

stats = stats.loc[(stats['Team'] != 'Team') & (stats['Team'].notna())]

#Convert to numeric and reset indices

stats['ORtg'] = pd.to_numeric(stats['ORtg'])
stats['DRtg'] = pd.to_numeric(stats['DRtg'])
stats['AdjT'] = pd.to_numeric(stats['AdjT'])
stats['NetRtg'] = pd.to_numeric(stats['NetRtg'])

stats = stats.reset_index(drop = True)

#This function takes a year and two team names and outputs a pandas series with the year and the differences in all the metrics between the teams

def compute_matchup(Year,Team1,Team2):
    diff = stats.iloc[stats.index[stats['Team'] == Team1][0],1:5] - stats.iloc[stats.index[stats['Team'] == Team2][0],1:5]
    diff.index = ['DORtg','DDRtg','DAdjT','DNetRtg']
    Yearlab = pd.Series([Year],index=['Year'])
    Namelab = pd.Series([Team1 + " v " + Team2],index=['Name'])
    return(pd.concat([Yearlab,Namelab,diff]))

#Example of using function to build a data frame and export 

df_out = pd.DataFrame(columns = ['Year','Name','DORtg','DDRtg','DAdjT','DNetRtg'])

A = 'Duke'
B = 'Arizona'
Y = 2026
df_out = pd.concat([df_out,compute_matchup(Y,A,B).to_frame().T],ignore_index=True)

num_cols = ['Year','DORtg', 'DDRtg', 'DAdjT', 'DNetRtg']
for col in num_cols:
    df_out[col] = pd.to_numeric(df_out[col], errors='coerce')

df_out['Name'] = df_out['Name'].astype(str)
df_out = df_out.round(2)
df_out.to_csv('~/newpredict.csv',float_format='%.2f')