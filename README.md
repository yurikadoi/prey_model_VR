# prey_model_VR

# Rotary Encoder
**Rotary encoder was introduced on 11/1/18. Below is the description of changes that are made due to this.
- I created a new movement function called "moveWithTorqueSencor". It was originally written by HyngGoo Kim to use for a torque sensor. Yurika Doi modified so that it can be used with the rotary encoder. This program basically read the input signal from Channel 5 (to which the rotary encoder is connected to as of 11/1/18), substract the baseline offset, and use that value as y-axis velocity.
The line 8 (data = peekdata(vr.ai, 25)) decides how many milliseconds (in this case 25 msec) it uses for the time window of averaged speed. You can make it shorter if you want less delay but you have to watch out for jittering.

- Before using this movement function (moveWithTorqueSencor), " flush_water_fromHG" needs to be run. This program is originally written by HyunGoo and Yurika modified it. It flushes the water as well as reads the initial baseline of each input channel. The baseline signal from the rotary encoder will be saved in a global variable called "idle_voltage_offset" and it will be used in "moveWithTorqueSencor" for substraction.

- The experiment variable called "scaling" has to be changed in the virmen experiment. As of 11/1/2018, the scaling value of [0 -100] seems to be working well but it has to be calibrated compared to the optical mouse movement. 

- VirMenInitDAQ was slightly modified so that there is another analog input for rotary encoder.

- how to program teensy.
Open arduino software. Make sure the device and port is specified as teensy.
Open RotaryEncoderAO_cont.ino (Obtained from HyungGoo).
Verify the code and upload it.
Once the upload is completed, check the singal in the test pannel in NIMAX software. Use RSE.
# prey model analysis
there is an event trigger that's sent when the switch happens (starting on Oct 18th)
which is (-(vr.A+.5)) instead of normal track App event signal
its either -2.5 or -4.5
