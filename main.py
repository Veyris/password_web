from flask import Flask, redirect, url_for, render_template, request
import pwned as pwnd
import strength as strong

app = Flask(__name__)

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/password_pwned", methods=["POST", "GET"])
def pwned():
    if request.method == "POST":
        password = request.form["pass"]
        if password == "":
            return render_template("/pwned/password_pwned.html", content_bool="False", content_error="You must enter something (Input-Field was empty).")
        else:
            found = pwnd.check_pwned_databaseAPI(password)
        
            if found is True:
                res = "True"
                res_content = "Unfortunately - Your Password was found on haveibeenpwned!"
                return render_template("/pwned/password_pwned.html", content_bool="True", res = res, res_content = res_content, password=password)

            else:
                res = "False"
                res_content = "Congratulations: Your Password was not found on haveibeenpwned!"
                return render_template("/pwned/password_pwned.html", content_bool="True", res = res, res_content = res_content, password=password)
    else:
        return render_template("/pwned/password_pwned.html", content_bool="False")

@app.route("/password_strength", methods=["POST", "GET"])
def check_strength():
    if request.method == "POST":
        password = request.form["pass"]
        if password == "":
            return render_template("/strength/password_strength.html", content_error="You must enter something (Input-Field was empty).")
        else:
            print(f"REQUEST FOR STRENGTH: {password}")
            checked = strong.checkStrength_zxcvbn(password)
            name_of_pass = checked[0]
            score = checked[1]
            guesses = checked[2]
            estimated_on_thrott = checked[3][0]
            estimated_on_thrott_sec = checked[3][1]
            estimated_on = checked[3][2]
            estimated_on_sec = checked[3][3]
            estimated_off_slow = checked[3][4]
            estimated_off_slow_sec = checked[3][5]
            estimated_off = checked[3][6]
            estimated_off_sec = checked[3][7]
            feedback_warning = checked[4]
            feedback_suggestion = checked[5]
            print(feedback_warning)
            print(feedback_suggestion)
            warning_one = ""
            

            if len(feedback_warning) > 0:
                warning_one = feedback_warning
                        
            sugg_one = ""
            sugg_two = ""

            if len(feedback_suggestion) == 1:
                sugg_one = feedback_suggestion[0]
            elif len(feedback_suggestion) == 2:
                 sugg_one = feedback_suggestion[0]
                 sugg_two = feedback_suggestion[1]
            
            print(warning_one)
            
            print(sugg_one)
            print(sugg_two)

            return render_template("/strength/password_strength_result.html", password = name_of_pass, score = score, guesses = guesses, 
            estimated_off = estimated_off, estimated_off_slow = estimated_off_slow, estimated_on = estimated_on, estimated_on_thrott = estimated_on_thrott,
            estimated_off_sec = estimated_off_sec, estimated_off_slow_sec = estimated_off_slow_sec, estimated_on_sec = estimated_on_sec, 
            estimated_on_thrott_sec = estimated_on_thrott_sec, warning_one = warning_one, sugg_one = sugg_one, sugg_two = sugg_two, len_pass = len(password))


    else:
        return render_template("/strength/password_strength.html")

@app.route("/faq")
def help():
        return render_template("/help.html")

if __name__ == "__main__":
	app.run()