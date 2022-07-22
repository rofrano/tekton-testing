# Set Up the Lab Environment

You have a little preparation to do before you can start the lab.

## Open a Terminal

Open a terminal window by using the menu in the editor: Terminal > New Terminal.

![Terminal](images/01_terminal.png)

In the terminal, if you are not already in the `/home/projects` folder, change to your project folder now.

```bash
cd /home/project
```

## Clone the Code Repo

Now get the code that you need to test. To do this, use the `git clone` command to clone the git repository:

```bash
git clone https://github.com/ibm-developer-skills-network/wtecc-CICD_PracticeCode.git
```

Your output should look similar to the image below:

![Git Clone](images/01_git_clone_code.png)

## Change into the Lab Folder

Once you have cloned the repository, change to the lab directory.

```bash
cd wtecc-CICD_PracticeCode/labs/05-build-an-image/
```

You are now ready to start the lab.

### Optional

If working in the terminal becomes difficult because the command prompt is very long, you can shorten the prompt using the following command:

```bash
export PS1="[\[\033[01;32m\]\h\[\033[00m\]: \[\033[01;34m\]\W\[\033[00m\]]\$ "
```
