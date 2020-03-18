# ARrehab
AR rehabilitation app designed for UCSF children's hospital.
This is a research project done under the advisement of Professor Allen Yang and Kat Quigley.

To access these files please checkout the content branch: `git checkout content`

## Adding content via Github's Web interface:
- [Uploading files](https://help.github.com/en/github/managing-files-in-a-repository/adding-a-file-to-a-repository)
- [Editing files](https://help.github.com/en/github/managing-files-in-a-repository/editing-files-in-your-repository)
    - Note that not all files are editable so you may need to just delete and reupload those files.

## Adding content via Terminal:
1. `git checkout content` Make sure you are in the content branch. 
    1. If it errors, try `git stash`
    2. Run `git checkout content` again
    3. `git stash pop`
1. `git pull` Gets all the latest changes other people made.
2. `git status` This will highlight all the files you changed in red and everything ready to commit in green.
3. `git add <filename>` Add the red files that you want to commit / save.
4. `git commit -m "<message>"` Commit / save the files. Write a message so people know what you changed.
5. `git push` Let the world know what you changed.
