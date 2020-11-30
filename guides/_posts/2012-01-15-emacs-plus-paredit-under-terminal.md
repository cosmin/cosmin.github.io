---
layout: post
title: Emacs + paredit under terminal
---

# Emacs + paredit under terminal (Terminal.app, iTerm, iTerm2)

<p class="meta">15 January 2012 - Melbourne, Australia</p>

I prefer to use Emacs in a full-screen terminal window. One problem that has plagued me until today though has been the lack of proper Control and Meta arrow combinations when working at the terminal. Especially when working with [paredit](http://www.emacswiki.org/emacs/ParEdit which frequently involves the use of `C-left`, `C-right`, `C-M-left`, `C-M-right` and less frequently of `M-up` and `M-down`. To get paredit to work properly I kept switching to Cocoa Emacs (in case you didn't know, you can install Cocoa emacs with `brew install emacs --cocoa` if you are using "homebrew) )

Today I decided to get to the bottom of this problem at any cost. First, I suspected that Control arrow combinations were not being sent properly by my terminal, in my case iTerm2. You can also fix this however for Terminal.app or the original iTerm.

### iTerm2 key bindings

Select Profiles > Open Profiles... from the menu bar, or press Command-O and take a look at the default profile. Click on the *Keys* section. While you are here verify you have _Left Option_ and _Right Option_ as `+Esc`. For the arrow key fixes though you will need to add a series of key shortcuts. The easiest way to get started is select _Load Preset..._ > _xterm Defaults_.

This will map C-up, C-down, C-right, and C-left to send the following escape sequences:

<pre>
C-up    : Esc-[1;5A
C-down  : Esc-[1;5B
C-right : Esc-[1;5C
C-left  : Esc-[1;5D
</pre>

It will also define Shift arrows and Control-Shift arrows, but we don't care about those at the moment. These are not quite sufficient, but before we go any futher, let's make sure we can get these to work in Emacs.

### Check Control-arrow bindings within Emacs

Open up a new terminal window and then open emacs at the terminal with `emacs -nw`. Now, with paredit turned off, try `C-left` and `C-right`, which should most likely move a word at a time left and right respectively. To verify Emacs is picking up the correct keys you can also try `C-h k` for _Describe key_ followed by the key combination. For example, `C-h k C-left` should display

```
<C-left> runs the command backward-word, which is an interactive
compiled Lisp function in `simple.el'.

It is bound to <C-left>, <M-left>, M-b, ESC <left>.

(backward-word &optional ARG)

Move backward until encountering the beginning of a word.
With argument ARG, do this that many times.

[back]
```

As long as `TERM` is set to `xterm` the above bindings should work automatically in Emacs. Should you have to define your own bindings for these escape sequences you could do so with

<pre><code>
(define-key input-decode-map "\e[1;5A" [C-up])
(define-key input-decode-map "\e[1;5B" [C-down])
(define-key input-decode-map "\e[1;5C" [C-right])
(define-key input-decode-map "\e[1;5D" [C-left])
</code></pre>

Note that _input-decode-map_ is only defined starting with Emacs 23.

### Paredit

At this point you should have `C-left` working outside of paredit. Now turn on paredit mode (`M-x paredit-mode`) and try C-left and C-right again. Chances are you will see `[1;5D` and `[1;5C`. If this happens only in paredit mode, then the culprit is most likely the bidning of `M-[`. You can figure this out by trying _describe key_ again. If you try `C-h k C-left` you will most likley see

<pre>
M-[ runs the command paredit-bracket-wrap-sexp, which is an
interactive Lisp function in `paredit.el'.

It is bound to M-[.

(paredit-bracket-wrap-sexp &optional N)

Wrap a pair of bracket around a sexp

M-[

(foo |bar baz)
  ->
(foo [|bar] baz)
</pre>

Huh?

### Where does M-[ come from?

Each time you press Control + left arrow the terminal will send the following sequence as defined above: `ESC [ 1 ; 5 D`. Emacs starts interpreting this sequence, but it gets an early match on `ESC [` which is the same as `M-[` and invokes `paredit-bracket-wrap-sexp`. We need to turn off this behavior, which we can do by putting the following in `~/.emacs`

<pre><code>
(require 'paredit)
(define-key paredit-mode-map (kbd "M-[") nil)
</code></pre>

Once you load the above code, try `C-left` again in paredit. If that works, you are ready for the next step.

### Add Meta-arrow and Control-Meta-arrow to iTerm2

The _xterm Defaults_ only provided us with certain key bindings. Go back to the profile key bindings under iTerm2 and add bindings for the following:

<pre>
M-up      : Esc-[1;4A
M-down    : Esc-[1;4B
M-right   : Esc-[1;4C
M-left    : Esc-[1;4D

C-M-up    : Esc-[1;8A
C-M-down  : Esc-[1;8B
C-M-right : Esc-[1;8C
C-M-left  : Esc-[1;8D
</pre>

To do this, click on the + sign, type the key sequence, then under _Action:_ select _Send Escape Sequence_ and type in the escape seequence starting with `[1;`. You can look as an example at the values for Control-left and friends that were added when you loaded the _xterm Defaults_ map.

Why these values? I have no idea. I looked at the escape sequences for plain arrow keys, Shift-arrow keys and Control-arrow keys and I decided to experiment a little in the neighboring spaces, using `C-h k` to figure out which key sequence is bound to what I want. If you find a better explanation please let me know.

### iTerm

If you are using iTerm you can add key bindings as follows:

Bookmarks > Manage Profiles > Keyboard Profiles > xterm and under _Key map settings:_ add (by clicking on the + sign)

<pre>
Key: cursor left
Modifier: Control
Action: send escape sequence

[1;5D
</pre>

Add the remaining key bindings using the above format and the values from the iTerm2 table.

### Terminal.app

In Terminal.app you will need to add a few key bindings by going to Preferences > Settings > Keyboard. The end result will be the same as iTerm2 but the interface is slightly different.

<pre>
Key: cursor left
Modifier: Control
Action: send string to shell

\033[1;5D

</pre>

where `\033` represents Escape. For the other keys refer to the map for iTerm2 above.
