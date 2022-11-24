import hashlib
import requests

def check_pwned_databaseAPI(password):
    """
        Method checks if a given password is leaked on pwned database
        @params:
            password   - Required  : Password to check with pwned-API call (String)
        @returns:
            Boolean if password is in wordlist(True) or not(False)
        """
    get_hash = hashlib.sha1()
    get_hash.update(password.encode())
    sha1_password = get_hash.hexdigest()

    # calls haveibeenpwned API with the first 5 Bytes of Hash for range check
    pwned_API_results = requests.get("https://api.pwnedpasswords.com/range/" + sha1_password[:5])

    # gets last 35 chars of Hash for comparison with results of API- Call 
    comparison_hash = sha1_password[-35:].upper()
    result_hashes = pwned_API_results.text.split()

    password_in_pwned = False

    # compares every result hash from 
    for get_hash in result_hashes:
        if get_hash[:35]==comparison_hash:
            password_in_pwned = True
            print(f"Password Match found for Password {password} in Pwned Wordlist! Continue...")

    return password_in_pwned