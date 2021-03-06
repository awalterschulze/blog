---
title: "Streaming Pair Programming from AWS"
date: 2020-05-12T09:22:08+01:00
tags: ["twitch", "aws", "teamviewer", "pair programming", "zoom", "coq", "vscode"]
---

![Missing](https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/FilmStrip.png "FilmStrip")

## Why?

  - **Why Streaming?** One of the advantages of living in a big city, like London, is not just that you don't have to own a car. It also makes it easier to find like minded people. People who are interested in learning the same thing you are and who are at a similar level in their learning experience on that topic, people you can form a study group with. I remember that working in, Stellenbosch, South Africa, I had to drive an hour and a half, one way, to Scarborough, Cape Town to find a group of about ten people interested in functional programming.  
<center>
<iframe src="https://www.google.com/maps/embed?pb=!1m28!1m12!1m3!1d1757916.0067339428!2d17.632468364941275!3d-34.08608619022217!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!4m13!3e0!4m5!1s0x1dcdb2f75188e2a5%3A0x7009aa00dee36be2!2sStellenbosch%2C%20South%20Africa!3m2!1d-33.9321045!2d18.860152!4m5!1s0x1dcc14ff23836223%3A0xc728558c5dcf53ac!2sZensa%20Lodge%2C%20534%20Egret%20St%2C%20Scarborough%2C%207975%2C%20South%20Africa!3m2!1d-34.199730699999996!2d18.375520599999998!5e1!3m2!1sen!2suk!4v1587292763786!5m2!1sen!2suk&zoom=20" width="600" height="450" frameborder="0" style="border:0;" allowfullscreen="" aria-hidden="false" tabindex="0"></iframe>
</center>
  Things have since changed with regards to functional programming at Stellenbosch University, where Haskell is now being taught in a popular choice module, but what if I wanted to study Coq programming next.  What if there was a way to share some of the study group I found in London with others?  Streaming on Twitch seems to be a way to accomplish this. What better place for streaming Coq, "the world's geekiest computer game".

  - **Why Pair programming?** Pair programming on a Coq project, where I am still learning the language, libraries and underlying theory, has been more educational to me than I could have ever imagined.  If I was to share something, the pair programming had to be part of it.

  - **Why AWS?** tl;dr more CPU! A friend from the study group and I started pair programming some Saturdays in coffee shops. This evolved into a video call, where it was easy to include a whole study group. Video calling in general is not CPU friendly and Zoom is no exception.  If you are also running OBS (the streaming software), you have two programs both competing for 250% of your 400% CPU.  At some point typing into the editor, felt like I was typing into a remote terminal over a dial up modem.  AWS allows us to rent a beast of a machine which could handle all of this including Teamviewer at 25% CPU.

  > Quick, everyone who knows what Twitch is Google what a dial up modem is and everyone who knows what a dial up modem is, you may now Google what Twitch is.

## Setup

I thought streaming pair programming was going to be easy.
I thought it would be as easy as Ted's setup for [remote pair programming on twitch with zoom](https://www.tedmyoung.com/remote-pair-programming-on-twitch-with-zoom/), all running on my local machine.

My laptop couldn't handle it and this required me needing to rent an AWS Server, which in turn led to a longer than expected setup process.  I almost gave up when I was 90% done and needed some encouragement from a friend to push me over the finish line.

1. [Setup Twitch](#Twitch)
2. [Find an appropriate AWS machine](#AWSMachine)
3. [Ask amazon to lift CPU limit](#CPULimit)
4. [Update security group to enable remote desktop](#Security)
5. [Launch and log into server using Remote Desktop](#RemoteDesktop)
6. [Update internet explorer security](#IE)
7. [Install and setup Teamviewer](#Teamviewer)
8. [Install virtual sound card](#Sound)
9. [Install and setup Zoom](#Zoom)
10. [Install and setup OBS](#OBS)
11. [Install and setup IDE](#IDE)
12. [Remap keys](#Remap)
13. [Choose a method of collaboration](#Collab)
14. [Stream](#Stream)

### Setup Twitch {#Twitch}

Technically you can stream to Twitch or Youtube.
I chose Twitch, since this is apparently more popular with coders.

Go to [twitch.tv](https://www.twitch.tv/) and create an account.

Now we want to setup Twitch to preserve you videos for later viewing, so viewers don't always have to watch at the exact time that the stream is occurring.

  - Go to you channel https://twitch.tv/awalterschulze
  - Click on your profile in the top right corner and click on `Settings`

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/TwitchProfile.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Click on `Channel and Videos`

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/TwitchSettings.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Enable `Store past broadcasts` 

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/TwitchStore.png" style="padding:20px;max-height:300px;display:inline-block"></img>

Next you need an image to display on your channel when you are offline.

Scroll down to `Video Player Banner` and click `Update`.

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/VideoBanner.png" style="padding:20px;max-height:300px;display:inline-block"></img>

Next click on the hamburger on the top left and then click on `Stream Manager`.

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Hamburger.png" style="padding:20px;max-height:300px;display:inline-block"></img>

Under `Quick Actions` click `Edit Stream Info`

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/QuickActions.png" style="padding:20px;max-height:300px;display:inline-block"></img>

Finally set the Category as `Science & Technology`.

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/EditStream.png" style="padding:20px;max-height:300px;display:inline-block"></img>

Unfortunately there is no coding category.  Apparently there was one, but it has been shutdown and grouped into the Science & Technology category.

### Find an appropriate AWS machine {#AWSMachine}

We found the
[Microsoft Windows Server 2016 with NVIDIA GRID Driver](https://aws.amazon.com/marketplace/pp/Amazon-Web-Services-Microsoft-Windows-Server-2016-/B073WHLGMC) machine. It is a `g3.4xlarge`, which has 16 cores.
This setup with 16 cores ended up running at 25% CPU, so I wouldn't recommend a 4 core machine.  I chose windows over linux, because this **is** "the year of the linux desktop".  If you are new to AWS, you won't be able to launch this yet and you will need to increase your CPU limit, see instructions in the next section.

This server looks expensive and it is not cheap, but given you are only paying for it when it is running, if you are disciplined in stopping the server, when you are not using it, it can be affordable, depending on how much you intend to use it.  Now is a good time to make that calculation and decide whether you can live with the hourly rate, which is about $2 per hour, at the time of writing.

### Ask Amazon to lift CPU Limit {#CPULimit}

  - Create an AWS account or log into your existing one by going to your [AWS Console](https://console.aws.amazon.com/)
  - At the top, click `Services` and from the menu under `Compute` select [EC2](https://console.aws.amazon.com/ec2)
  - On the side menu, click `Limits`
  - Search for CPU and select `Running On-Demand All G instances`, this is if you also chose a machine that starts with `g`, like the `g3.4xlarge`.  If you are new to AWS, like me, you will need to increase your `Current Limit` from `0` to `16` to be able to launch the chosen machine. I selected `32`, just in case.  If your limit is already high enough you can skip this section.
  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSLimits.png" style="padding:20px;max-height:300px;display:inline-block"></img>
  - Click `Request limit increase` in the top corner.
  - A form will open:
    + Make sure `EC2 Instances` is selected for `Limit type`
  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSCaseClassification.png" style="padding:20px;max-height:300px;display:inline-block"></img>
    + Select your Region, `All G instances` if you are requesting a machine that starts with `g`, like the `g3.4xlarge`.  Choose a `New limit value` of `16` if that is appropriate for your selected machine, like the `g3.4xlarge`.
  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSRequests.png" style="padding:20px;max-height:300px;display:inline-block"></img>
    + Finally describe your use case in the `Use case description` box.
  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSCaseDescription.png" style="padding:20px;max-height:300px;display:inline-block"></img>
  - And now you will have to wait for amazon's human reviewers to look at the case and decide whether to increase the limits.  I waited about 3 days.
  - Then you should be able to launch in the instance.

## Update security group to enable remote desktop {#Security}

AWS Windows servers don't let you log into them using remote desktop by default.
You have to create a new security group or update the default security group to allow for RDP traffic.

  - go to [AWS Console](https://console.aws.amazon.com/)
  - go to [EC2](https://console.aws.amazon.com/ec2)
  - On the left, under `Network & Security`, click on `Security Groups`.
    <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/SecurityGroups.png" style="padding:10px;max-height:300px;display:inline-block"></img>
  - Now you need to `Create security group` or `Edit Inbound Rules` for an existing group. To edit an existing group, for example the `default` Security group, like I did: Select it, click on `Actions` and then `Edit Inbound Rules`.
  -  Next, add two new rules, using the `Add Rule` button:
    <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AWSRDP.png" style="padding:20px;max-height:300px;display:inline-block"></img>
    `Type: RDP, Source: 0.0.0.0/0` and `Type: RDP, Source: ::/0`
  - Finally click `Save rules`. Now you should be able to use remote desktop to log into your server.

## Launch and log into server using Remote Desktop {#RemoteDesktop}

If AWS has approved your CPU limit increase, you can move onto this step.

  - If you are on a mac, like me, you will need to install [remote desktop](https://apps.apple.com/us/app/microsoft-remote-desktop-10/id1295203466?mt=12).
  - Now is the time to launch your instance
    [Microsoft Windows Server 2016 with NVIDIA GRID Driver](https://aws.amazon.com/marketplace/pp/Amazon-Web-Services-Microsoft-Windows-Server-2016-/B073WHLGMC)
    + click on `Continue to Subscribe`.  This doesn't cost anything for this specific instance, since it is an instance marketed by AWS themselves, but other instances on AWS Marketplace, might cost a subscription fee.
    + click on `Continue to Configuration`
    + pick your specific region, we chose `EU (Ireland)`.
    + check that the `Software Pricing` is `$0/hr` if you haven't chosen a different machine. `Infrastructure Pricing` should have a real cost associated with it.
    + click on `Continue to Launch`
  - go to [EC2](https://console.aws.amazon.com/ec2)
  - click on Instances on the left side menu.
  - Now the machine might already be started, or initializing, but if is not, then right click on the instance, select `Instance State` and then `Start`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Instances.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Wait for `Status Checks` to turn from `Initializing` to `2/2 checks passed`.
  - Right click on your machine and click `Connect`

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Connect.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Click on `Download Remote Desktop File`

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/DownloadRemoteDesktopFile.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - You will also need to click `Get Password`, but I will leave those details up to you.
  - Now open the downloaded remote desktop file, using remote desktop.
  - You will need to paste in the password you got from `Get Password`.
  - Well done! You can now remotely control the AWS windows server, from your home computer, using remote desktop.
  - Before you possibly `stop` your machine, remember to create an image in the AWS E2 Instances, otherwise you could lose your work?

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/CreateImage.png" style="padding:20px;max-height:300px;display:inline-block"></img>

## Update Internet Explorer security {#IE}

This first problem you will encounter on your windows server, is Internet Explorer has been severely limited, via a security setting.  Basically, you won't even be able to download another browser. Let's fix that.

On your windows server, via Remote Desktop:

  - Open `Server Manager`

    <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/ServerManager.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - In the left panel, Select `Local Server`
  - In the top panel with heading `Properties`, in the right middle of that panel, you will see `IE Enhanced Security Configuration`.  Mine already, says `Off`, but yours will say `On`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/IEEnhanced.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Click on `On` and select `Off` for both users and Administrator.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/InternetExplorerEnhanced.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Click `Ok`.
  - Close `Server Manager`
  - Open Internet Explorer, it should now show that `Caution: Internet Explorer Enhanced Security Configuration is not enabled`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/InternetSecurityNotEnabled.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Download and install your browser of choice.

## Install and setup Teamviewer {#Teamviewer}

Why do we need Teamviewer, when Remote Desktop is working so well?  It all comes down to sound.  A server doesn't have a sound card, but we want to stream the sound from our video call to Twitch.  We will need to install a virtual sound card and this doesn't play nicely with Remote Desktop.

VNC is another option, but we opted for Teamviewer, because we will need cloud connect for a user friendly experience and this is free for personal use on Teamviewer, where I found with VNC servers that it looked like I needed to pay.  I could be wrong.
In the end Teamviewer was more user friendly for me and solved the sound problem.

  - Install [Teamviewer](https://www.teamviewer.com/) on your mac and windows server.
  - Once installed, on the windows server, Sign in or create a Teamviewer account and sign in.
  - On the windows server, Tick `Start Teamviewer with Windows` and `Easy access for ... is granted`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/GrantEasyAccess.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - On your mac, sign into your Teamviewer account.
  - You should now see the machine under `Computer & Contacts`.
  - Double Click on the machine to connect.
  - You should get a notification about `multiple monitors`. This server has two virtual monitors, which is going to be very useful for streaming.  Click `Ok`

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/MultipleMonitors.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - You should now see a locked screen, that requires `Ctrl+Alt+Delete` to unlock.  Click on `Actions` in the top menu bar and then select `Ctrl+Alt+Delete`.
  - You should now be able to log into your Administrator account.  You might have a problem here, which is copy and paste is not working, at least it didn't work for me.
  - Click on `Actions` again in the top menu bar and then select `Send key combinations`. Try again. You might still have a problem, just like me.  You are not alone, but it did eventually start working. Unfortunately, I never got to understand why.

    <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/KeyCombinations.png" style="padding:20px;max-height:300px;display:inline-block"></img>
 
  - Now is as good a time as any to create a user account.  If you are unable to log into Teamviewer, yet.  Go to remote desktop and create a user account, with a password that you can remember and type without copying and pasting.  You can keep your Administrator account secure and only ever need to use it with Remote Desktop.  Only your user account will need to work with Teamviewer and might need a password that you can actually remember and type out.
  - Now you can use Teamviewer to log into your user account.
  - One more thing I would encourage you to Configure is to Optimize for speed over quality of image.  If you are planning to code, then typing is a big part of that and typing feedback can be very important. Go to Teamviewer's `Preferences`. Click on `Remote Control` and from the `Quality` dropdown, select `Optimize speed`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/OptimizeSpeed.png" style="padding:20px;max-height:300px;display:inline-block"></img>

## Install virtual sound card {#Sound}

On the windows server:

  - Download [VB-Audio Software's VB-Cable](https://www.vb-audio.com/Cable/). We don't need the VB-Cable A+B, etc. We only need the `VBCABLE_Driver_Pack43.zip`.
  - Unzip and run `VBCABLE_Setup_x64`.
  - In Teamviewer, go to your sound card settings, by right clicking in the bottom right corner on the little speaker and selecting `Playback devices`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/LittleSpeaker.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Under `Playback` you should see `Cable Input` by `VB-Audio Virtual Cable`. Please ignore the other playback devices, I tried several routes before realizing remote desktop was incompatible with virtual sound cards and I haven't taken the time to clean up the other virtual sound cards I ended up not using or even evaluating.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Sound.png" style="padding:20px;max-height:300px;display:inline-block"></img>
    
  - The virtual sound card is now installed, we are going to use it to thread the zoom output sound into OBS input sound and stream this to Twitch.

## Install and setup Zoom {#Zoom}

I chose [Zoom](https://zoom.us/), because:

  - Zoom allows screen sharing and doesn't turn off your webcam to do so.
  - Zoom's window in which participants are viewed is the prettiest to put in a corner of your screen and has `always on top` enabled automatically.

I might reconsider this choice in future, since Zoom calls over 40 minutes are not free and removing this from the setup would moderately reduce the overall cost of this setup.

Whichever Video Call program you choose, it is important to setup the sound output.  Here is how I did it for Zoom, but you should easily be able to reproduce this with any Video Calling program.

  - Install Zoom on your windows server and create a new account.  You are going to need two accounts for Zoom. One for the windows server and one for your home computer.  Only the account that will be hosting the meetings will need to be a paid account, if you are planning on pair programming longer than 40 minutes at a time, like me.
  - Go to Zoom settings and then `Audio`.  Set the Speaker to `CABLE Input (VB-Audio Virtual Cable)`, the Microphone doesn't matter as we won't be using the server's microphone.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/ZoomAudio.png" style="padding:20px;max-height:300px;display:inline-block"></img>

Now Zoom will send its output, which should include everyone on the call's audio to `CABLE Input..`, which we are going to capture using `OBS`.

## Install and setup OBS {#OBS}

[OBS Studio](https://obsproject.com/) is used to Stream to Twitch, Youtube, etc. Now is probably a good time to skim through a [better blog](https://www.freecodecamp.org/news/lessons-from-my-first-year-of-live-coding-on-twitch-41a32e2f41c1/) to learn a bit more about OBS and how to use it.
There are also many videos that explains how to setup OBS.  We will not be going into that.  We will only be touching on the specific OBS configuration for this setup, namely how to route the audio and how to share our screen using the multiple monitors of this AWS Server.

  - Log into your windows server as Administrator. Installing OBS requires being logged in as Administrator, so I installed it using Remote Desktop.
  - Download and install [OBS Studio](https://obsproject.com/) and setup connection to Twitch.  There should be step by step instructions for doing so.
  - After installation, we can log back into our user, using Teamviewer.
  - Go to `View` in the top menu bar, under `Active monitor`, click `Show all monitors`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/ShowAllMonitors.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Open `OBS Studio` and drag it to the smaller second monitor. Your OBS will be less interesting than mine, since mine is already setup. OBS will be running on the small `monitor 2` and we will be using `monitor 1` for everything we want to stream to Twitch.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/DualMonitors.png" style="padding:20px;max-height:300px;display:inline-block"></img>
   
  - We can capture the sound from zoom that we have routed to `CABLE Input (VB-Audio Virtual Cable)` in OBS, by first creating a Scene. Click the `+` button in the `Scene` panel.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Scene.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Select our new scene and click the `+` button under `Sources` and select `Audio Output Capture`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AudioOutputCapture.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Select `Create New`, type a name and click `OK`.
  - Select the `Device` from the dropdown: `CABLE Input (VB-Audio Virtual Cable)` and click `OK`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Device.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - You should now be able to test the sound, by creating a Zoom call between your home computer and the windows server and see the green bar in the Audio Mixer move, when you talk.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Mixer.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - We can capture `monitor 1`, by adding another Source.  Click the `+` under `Sources` and select `Display Capture`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/DisplayCapture.png" style="padding:20px;max-height:300px;display:inline-block"></img>

  - Select `Create New`, type a name and click `OK`.
  - Select the `Device` from the drop down `Display 1...` and click `OK`.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/DisplayDevice.png" style="padding:20px;max-height:600px;display:inline-block"></img>

  - You can now test the sound and display by clicking the `Start Recording` button in OBS, creating a zoom call and watching and listening to yourself speak, by playing the recorded file.
    
## Install and setup IDE {#IDE}

This setup is specific to VSCode and Coq, but you can install any IDE for any programming language you want.

  - Install [VSCode](https://code.visualstudio.com/)
  - Install your programming language, in our case [Coq](https://coq.inria.fr/)
  - Install your VSCode plugin, in our case [VSCoq](https://github.com/coq-community/vscoq) and make sure it points to your Coq installation.
  - Turn off some suggestions. Suggestions are great for auto complete, but if they happen when you simply type space they can be disruptive and possibly over work the language server.  I found turning this one setting off `Editor > Suggest: Show Properties` in vscode, results in hints from VSCoq to only happen after I have typed some letters.

  <img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/AutoComplete.png" style="padding:20px;max-height:600px;display:inline-block"></img>

## Remap keys {#Remap}

Controlling a windows machine from a mac, means that several of your usual shortcuts no longer work.
Mac uses the Cmd key, where windows uses Ctrl key a lot. This is a simple fix on your mac.
Go into your keyboard settings, select `Modifier Keys` and remap Cmd to Ctrl.

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/Control.png" style="padding:20px;max-height:300px;display:inline-block"></img>

For the rest, I use Autohotkey to remap my most popular mac shortcuts to windows shortcuts.

  - Log in as Administrator.
  - Install [AutoHotkey](https://www.autohotkey.com/) on your windows server.

Create a script file: mac.ahk
```ahk
;Autohotkey script

;Ctrl+Shift+Left => Shift+Home
^+Left::Send +{Home}
;Ctrl+ShiftRight => Shift+End
^+Right::Send +{End}

^w::Send ^{F4}
^q::Send !{F4}
```

This script has to run as Administrator.
Right click on the file and choose `Run as Administrator`, when you log in as your normal user.
I needed to have Teamviewer's `Send key combinations` enabled, others have reported the opposite so play around with this.

## Choose a method of collaboration {#Collab}

If you want to do collaborative editing, instead of just having your pair programmers, be backseat coders. There are several options:

  - Teamviewer allows for multiple logins and that works great, since now your collaborators have full control.  You need to coordinate who is using the keyboard.  Also less obviously you are also sharing a copy and paste buffer.  So if one of you is doing something on their own computer and copies something, the other person can paste this into teamviewer onto your public stream, so be careful about copying passwords, etc.
  - Alternatively you can install [Live Share](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare), but we couldn't get this working with Coq's Proof View.  I hope we are wrong, because this would solve a lot of problems.
  - Screen share via Zoom allows multiple collaborators to switch between who is driving. Yes technically the server doesn't have to be the one that is sharing its screen with your collaborators.  Your collaborators can actually share their local screen and this shared screen can then be captured with OBS on the AWS server and streamed to Twitch.  In this case collaborators with limited CPU, might want to limit the amount of frames they are sharing.

1. Go to Zoom Settings
2. Click `Share Screen`
3. Click the `Advanced` button in the lower right hand corner.
4. Check the Limit your screen share box
5. Select 4 frames-per-second.

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/LimitFrames.png" style="padding:20px;max-height:600px;display:inline-block"></img>

## Stream {#Stream}

Finally you are ready to stream.

You will probably want to create pictures that you can use to display when you are:

 - Offline
 - Starting Soon
 - Taking a Break and possibly
 - Entering a password

<img src="https://awalterschulze.github.io/blog/streaming-pair-programming-from-aws/StreamOffline.png" style="padding:20px;max-height:600px;display:inline-block"></img>

Come check out the resulting stream: https://www.twitch.tv/awalterschulze

## Thank you

  - [Ayman Osman](https://github.com/aymanosman) for the idea of using AWS, tutoring me in how to use AWS and also encouraging me when I was about to give up.
  - [Max Heiber](https://github.com/mheiber) for the initial idea to stream Coq programming.
  - [Paul Cadman](https://github.com/paulcadman) for testing and searching and finding a way to limit the number of frames in Zoom, when my CPU was still struggling.
  - [Niels uit de Bos](https://github.com/Nielius) for testing the stream.
  