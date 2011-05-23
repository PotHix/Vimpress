" Copyright (C) 2011 PotHix <Willian Molinari>.
"
" This program is free software; you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation; either version 2, or (at your option)
" any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program; if not, write to the Free Software Foundation,
" Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
"
" ProjectCreator: Adrien Friggeri <adrien@friggeri.net>
" Maintainer:     PotHix <pothix@pothix.com>
" URL:            https://github.com/PotHix/vimpress
" Version:        0.12
" Last Change:    2011 May 23
"
" Read the README file for more informations about the Vimpress configuration

command! -nargs=0 BlogList exec('py blog_list_posts()')
command! -nargs=0 BlogNew exec('py blog_new_post()')
command! -nargs=0 BlogSend exec('py blog_send_post()')
command! -nargs=0 BlogPublish exec('py blog_publish()')
command! -nargs=0 BlogPreviewUrl exec('py blog_preview_url()')
command! -nargs=1 BlogOpen exec('py blog_open_post(<f-args>)')
command! -nargs=1 BlogDefault exec('py blog_define_default(<f-args>)')

python <<EOF
# -*- coding: utf-8 -*-
import urllib , urllib2 , vim , xml.dom.minidom , xmlrpclib , sys , os, string , re

# Loading settings
enable_tags = 1

def blog_edit_off():
    for i in ["i","a","s","o","I","A","S","O"]:
        vim.command('map '+i+' <nop>')

def blog_edit_on():
    for i in ["i","a","s","o","I","A","S","O"]:
        vim.command('map '+i+' <nop>')
        vim.command('unmap '+i)

def blog_send_post():
    blog_send(0)

def blog_publish():
    blog_send(1)

def blog_new_post():
    handler, blog_username, blog_password, blog_url = blog_load_info()
    def blog_get_cats():
        l = handler.getCategories('', blog_username, blog_password)
        s = ""
        for i in l:
            s = s + (i["description"].encode("utf-8"))+", "
        if s != "":
            return s[:-2]
        else:
            return s
    del vim.current.buffer[:]
    blog_edit_on()
    vim.command("set syntax=vimpress")
    vim.current.buffer[0] =   "\"=========== Meta ============\n"
    vim.current.buffer.append("\"StrID : ")
    vim.current.buffer.append("\"Title : ")
    vim.current.buffer.append("\"Cats  : "+blog_get_cats())
    if enable_tags:
        vim.current.buffer.append("\"Tags  : ")
    vim.current.buffer.append("\"========== Content ==========\n")
    vim.current.buffer.append("\n")
    vim.current.window.cursor = (len(vim.current.buffer), 0)
    vim.command('set nomodified')
    vim.command('set textwidth=0')

def blog_open_post(id):
    handler, blog_username, blog_password, blog_url = blog_load_info()
    try:
        post = handler.getPost(id, blog_username, blog_password)
        blog_edit_on()
        vim.command("set syntax=vimpress")
        del vim.current.buffer[:]
        vim.current.buffer[0] =   "\"=========== Meta ============\n"
        vim.current.buffer.append("\"StrID : "+str(id))
        vim.current.buffer.append("\"Title : "+(post["title"]).encode("utf-8"))
        vim.current.buffer.append("\"Cats  : "+",".join(post["categories"]).encode("utf-8"))
        if enable_tags:
          vim.current.buffer.append("\"Tags  : "+(post["mt_keywords"]).encode("utf-8"))
        vim.current.buffer.append("\"========== Content ==========\n")
        content = (post["description"]).encode("utf-8")
        for line in content.split('\n'):
          vim.current.buffer.append(line)
        text_start = 0
        while not vim.current.buffer[text_start] == "\"========== Content ==========":
          text_start +=1
        text_start +=1
        vim.current.window.cursor = (text_start+1, 0)
        vim.command('set nomodified')
        vim.command('set textwidth=0')
    except:
        sys.stderr.write("An error has occured when trying to open the blog post")

def blog_list_edit():
    try:
        row,col = vim.current.window.cursor
        id = vim.current.buffer[row-1].split()[0]
        blog_open_post(int(id))
    except:
        pass

def blog_list_posts():
    handler, blog_username, blog_password, blog_url = blog_load_info()
    lessthan = handler.getRecentPosts('',blog_username, blog_password,1)[0]["postid"]
    size = len(lessthan)
    allposts = handler.getRecentPosts('',blog_username, blog_password,int(lessthan))
    del vim.current.buffer[:]
    vim.command("set syntax=vimpress")
    vim.current.buffer[0] = "\"====== List of Posts ========="
    for p in allposts:
        vim.current.buffer.append(("".zfill(size-len(p["postid"])).replace("0", " ")+p["postid"])+"\t"+(p["title"]).encode("utf-8"))
        vim.command('set nomodified')
    blog_edit_off()
    vim.current.window.cursor = (2, 0)
    vim.command('map <enter> :py blog_list_edit()<cr>')

def blog_define_default(default_number):
    try:
        config_file_path = os.path.expanduser("~")+"/.vim/custom/configs.vim"
        new_content = []
        old_content = open(config_file_path).readlines()

        for i in old_content:
            blog_settings = i.split(",")
            blog_settings[0] = "[ ]"
            new_content.append(",".join(blog_settings))

        s = new_content[int(default_number)].split(",")
        s[0] = "[x]"
        new_content[int(default_number)] = ",".join(s)

        f = open(config_file_path, "w")
        for i in new_content:
            f.write(i)
        f.close()
    except:
        sys.stderr.write("Could not setup a default blog, do it manually on your configs.vim file")

def blog_send(publish=False):
    handler, blog_username, blog_password, blog_url = blog_load_info()

    strid = get_meta("StrID")
    title = get_meta("Title")
    cats = [i.strip() for i in get_meta("Cats").split(",")]
    if enable_tags:
        tags = get_meta("Tags")

    text_start = 0
    while not vim.current.buffer[text_start] == "\"========== Content ==========":
        text_start +=1
    text_start +=1
    text = '\n'.join(vim.current.buffer[text_start:])

    content = text

    post = {
        'title': title,
        'description': content,
        'categories': cats,
    }

    if enable_tags:
        post['mt_keywords'] = tags

    if strid == '':
        strid = handler.newPost('', blog_username, blog_password, post, 0)

        vim.current.buffer[get_line("StrID")] = "\"StrID : "+strid
    else:
        handler.editPost(strid, blog_username, blog_password, post, publish)

    vim.command('set nomodified')


def blog_preview_url():
    blog_url = re.sub("xmlrpc.*","",blog_load_info()[3])
    sys.stdout.write(re.sub("\n", "", blog_url + "?p=" + get_meta("StrID") + "&preview=true"))

def get_line(what):
    start = 0
    while not vim.current.buffer[start].startswith('"'+what):
        start +=1
    return start

def get_meta(what):
    start = get_line(what)
    end = start + 1
    while not vim.current.buffer[end][0] == '"':
        end +=1
    return " ".join(vim.current.buffer[start:end]).split(":")[1].strip()


#FIXME: I should find a better way to use it to not load everytime and duplicate code :(
def blog_load_info():
    try:
        f = open(os.path.expanduser("~")+"/.vim/custom/configs.vim")
        for i in f.readlines():
            info = i.split(",")
            if info[0] == "[x]": vimpress_informations = info

        f.close()
    except:
        vimpress_informations = False
        sys.stderr.write("No config file found at '~/.vim/custom/configs.vim'")

    if vimpress_informations and vimpress_informations[1] != "login":
        blog_username = vimpress_informations[1]
        blog_password = vimpress_informations[2]
        blog_url      = vimpress_informations[3]
    else:
        blog_username = blog_password = blog_url = False

    if blog_url:
        handler = xmlrpclib.ServerProxy(blog_url).metaWeblog

    return [handler, blog_username, blog_password, blog_url]


