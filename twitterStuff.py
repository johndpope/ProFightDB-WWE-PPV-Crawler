import tweepy
import sys

raw_keywords = ["Goldberg",
                "@Goldberg",
                "Kevin Owens",
                "@FightOwensFight",
                "Neville",
                "@WWENeville",
                "Rich Swann",
                "@GottaGetSwann",
                "Rusev",
                "@RusevBUL",
                "Cesaro",
                "@WWECesaro",
                "Jinder Mahal",
                "@JinderMahal",
                "Sheamus",
                "@WWESheamus",
                "Chris Jericho",
                "@IAmJericho",
                "Bayley WWE",
                "@itsBayleyWWE",
                "Sasha Banks",
                "@SashaBanksWWE",
                "Nia Jax",
                "@NiaJaxWWE",
                "Charlotte WWE",
                "@MsCharlotteWWE",
                "@WWETheBigShow",
                "The Big Show",
                "Braun Strowman",
                "@BraunStrowman",
                "Roman Reigns",
                "@WWERomanReigns",
                "Brock Lesnar",
                "@brocklesnar",
                "Sami Zayn",
                "@iLikeSamiZayn",
                "Samoa Joe",
                "@SamoaJoe",
                "Big E",
                "@WWEBigE",
                "Xavier Woods",
                "@XavierWoodsPhD",
                "Kofi Kingston",
                "@TrueKofi",
                "Titus O'Neil",
                "@TitusONeilWWE"
                "TJ Perkins",
                "@MegaTJP",
                "Tony Nese",
                "@TonyNese",
                "Brian Kendrick",
                "@mrbriankendrick",
                "R-Truth",
                "@RonKillings",
                "Noam Dar",
                "@NoamDar",
                "Mustafa Ali",
                "@MustafaAliWWE",
                "Mark Henry",
                "@TheMarkHenry",
                "Lince Dorado",
                "Karl Anderson",
                "@KarlAndersonWWE",
                "Luke Gallows",
                "@LukeGallowsWWE",
                "Gran Metalik",
                "Dana Brooke"
                "@DanaBrookeWWE",
                "Jack Gallagher",
                "Curtis Axel",
                "@RealCurtisAxel",
                "Bo Dallas",
                "@TheBoDallas",
                "Enzo Amore",
                "@WWEAaLLday21",
                "Big Cass",
                "@BigCassWWE",
                "Drew Gulack",
                "@DrewGulak",
                "Darren Young",
                "@DarrenYoungWWE"
    ]

consumer_key = "NIpL8bLC51VOLhMjSJh3NSop4"
consumer_secret = "Cam3Rq71EtUNWWGnuQ5Ri8uCRRLFK8GaYHmzibTiBDX9PMtVBI"
access_token = "277775427-F3Yv8lZzrtfcZq6s996XEb6UJRQZu1KPdFWKp1fC"
access_token_secret = "PZvfHA4oI5bv6KQb1lSLKlsS1g2V8WDgJhCrtEpCPN13d"

auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)

api = tweepy.API(auth)

class MyStreamListener(tweepy.StreamListener):
    
    def __init__(self,filepath = "public_tweets/trash/trash.txt"):
        super(MyStreamListener, self).__init__()
        self.file = open(filepath,"a") 

    def on_status(self, status):
        if (not hasattr(status, 'retweeted_status')):
            self.file.write(status.user.screen_name.encode('UTF-8') + " | " + str(status.created_at) + " | " + status.text.encode('UTF-8') + "\n")
            print(status.user.screen_name.encode('UTF-8') + " | " + str(status.created_at) + " | " + status.text.encode('UTF-8'))
            
    def on_exception(self, exception):
        print(str(exception))
        
print(str(sys.argv))
myStreamListener = MyStreamListener(filepath=sys.argv[1])
myStream = tweepy.Stream(auth = api.auth, listener=myStreamListener)
myStream.filter(track=raw_keywords)
