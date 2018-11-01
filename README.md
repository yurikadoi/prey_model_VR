# prey_model_VR

# Rotary Encoder
**Rotary encoder was introduced on 11/1/18. Below is the description of changes that are made due to this.
- I created a new movement function called "moveWithTorqueSencor". It was originally written by HyngGoo Kim to use for a torque sensor. Yurika Doi modified so that it can be used with the rotary encoder. This program basically read the input signal from Channel 5 (to which the rotary encoder is connected to), substract the baseline offset, and use that value as y-axis velocity.
The line 8 (data = peekdata(vr.ai, 25)) decides

- Before using this movement function (moveWithTorqueSencor), " flush_water_fromHG" needs to be run. This program is originally written by HyunGoo and Yurika modified it. It flushes the water as well as reads the initial baseline 

- how to program teensy.
Open arduino software. Make sure the device and port is specified as teensy.
Open RotaryEncoderAO_cont.ino (Obtained from HyungGoo).
Verify the code and upload it.
Once the upload is completed, check the singal in the test pannel in NIMAX software. Use RSE.
