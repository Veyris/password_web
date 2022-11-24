from zxcvbn import zxcvbn

def checkStrength(password):

    """
        Method checks the password strength of it with zxcvbn library.
        @params:
            password  : str,required (Password to check with zxcvbn (String))
        @returns:
            list with 5 values. 
            - [0] is Score reaching from 0-4. 0 -> risky password (< 10^3), 1 -> very guessable (< 10^6), 2 -> guessable (< 10^8)
            3 -> safely unguessable (< 10^10), 4 -> very unguessable (> 10^10)
            - [1] is number of guesses neccessary to crack the password
            - [2] is Guesses Log10
            - [3] is time needed to crack the password (gives 4 Values)
            - [4] is feedback/suggestions to improve Password- Strength
        """

    result = zxcvbn(password)
    
    name_of_pass = result["password"]
    score_of_pass = result["score"]
    needed_guesses = result["guesses"]
   
    feedback_warnings = result["feedback"]["warning"]
    feedback_suggestions = result["feedback"]["suggestions"]
    feedback = [feedback_warnings, feedback_suggestions]

    crack_time_on_throttling = "Online-Slow-Cracking\t (Throttled - 100 Trys per Hour): \t\tEstimated Time to Crack: " +str(result["crack_times_display"]["online_throttling_100_per_hour"]) + " (" +str("%.0f" % round(result["crack_times_seconds"]["online_throttling_100_per_hour"], 2)) + " seconds)"
    crack_time_on_nothrott = "Online-Cracking\t\t (None-Throttled - 10 Trys per Second): \tEstimated Time to Crack: " +str(result["crack_times_display"]["online_no_throttling_10_per_second"]) + " (" +str("%.0f" % round(result["crack_times_seconds"]["online_no_throttling_10_per_second"], 2)) + " seconds)"
    crack_time_off_slow = "Online-Slow-Hashing\t (10,000 Trys per Second): \t\t\tEstimated Time to Crack: " +str(result["crack_times_display"]["offline_slow_hashing_1e4_per_second"]) + " (" +str("%.0f" % round(result["crack_times_seconds"]["offline_slow_hashing_1e4_per_second"], 2)) + " seconds)"
    crack_time_off_fast = "Online-Fast-Hashing\t (10,000,000,000 Trys per Second): \t\tEstimated Time to Crack: " +str(result["crack_times_display"]["offline_fast_hashing_1e10_per_second"]) + " (" +str("%.0f" % round(result["crack_times_seconds"]["offline_fast_hashing_1e10_per_second"], 2)) + " seconds)"
    crack_time = [crack_time_on_throttling, crack_time_on_nothrott, crack_time_off_slow, crack_time_off_fast]

    analysis = [name_of_pass, score_of_pass, needed_guesses, crack_time, feedback]
    
    return analysis
