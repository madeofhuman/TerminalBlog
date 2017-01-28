# TerminalBlog

Create a blogpost in Blogger from the terminal. A Ruby app.

# Requirements:

    1. Your Blog Id
    2. A .txt file containing the blog post (which can be optionally html-formatted)

# Instructions:
    $ ruby TerminalBlog.rb -f path/to/file.txt -t "title of post" -l "label, for, post") [--publish]

    --publish is optional, leaving it out posts as draft. You'll have to confirm the post on the dashboard.
