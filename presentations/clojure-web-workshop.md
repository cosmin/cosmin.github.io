## install Leiningen 2

https://github.com/technomancy/leiningen/

## create a new noir project

```
lein new noir clojerks
```

# use latest version of Noir

edit `project.clj`

```
[noir "1.3.0-beta8"]
```

## start the application

```
lein run
```

browse to http://localhost

## auto-reloading

* open `src/clojerks/views/welcome.clj`
* change `(defpage "/welcome"` to `defpage "/"`
* refresh the browser
* remove `[noir.content.getting-started]`

## layout

download [Twitter Bootstrap](http://twitter.github.com/bootstrap/)

```
unzip bootstrap.zip
rm -r resources/public
mv bootstrap resources/public
```

open `src/clojerks/views/common.clj` and change the `(defpartial layout` definition as follows

```
(defpartial layout [title & content]
    (html5
      [:head
       [:title (str "Clojerks: " title)]
         (include-css "/css/bootstrap.css")
         (include-css "/css/site.css")]
      [:body
       [:div.navbar.navbar-fixed-top
        [:div.navbar-inner
         [:div.container
          [:a.brand {:href "/"} "Clojerks"]
          [:ul.nav
           [:li.active [:a {:href "/"} "Home"]]]]]]
       [:div.container
        [:header.subhead
         [:h1 title]]
        content]]))
```

create a `resources/public/css/site.css` file with

```
body {
    padding-top: 60px;
}

h1 {
    margin-bottom: 1em;
}
```

## build the application

### display a list of books

```
(defpartial display-book [book]
  [:li book])

(defpage "/" []
  (let [books ["Design for Hackers",
               "Clojure Programming"]]
        (common/layout
            [:h1 "Books"]
            [:ul
                (map display-book books)
            ])))
```

### add a new book

add to the bottom of the "/" page

```
[:a {:href "/add"} "Add a book"]
```

and create a new page for adding

```
(defpage "/add" []
  (common/layout
   "Add a book"
   [:div.row
    [:div.span3
     [:form {:method "POST"}
      [:label {:for "title"} "Title"]
      [:input {:type "text"
             :name "title"
                    :placeholder "Book title..."}]
      [:p.help-block "Enter the book title"]
      [:button.btn {:type "submit"} "Add"]]]]))
```

bind the post action

```
(defpage [:post "/add"] {:as book}
  (session/put! "books" (conj (session/get "books" []) (:title book)))
    (response/redirect "/"))
```

add new requires

```
[noir.session :as session]
[noir.response :as response]
```

and change the homepage to use the books from session

```
(let [books (session/get "books" [])]
```

### validation

let's make sure the book name is valid

add the following require

```
[noir.validation :as validation]
```

define a function to validate

```
(defn valid? [{:keys [title]}]
  (validation/rule (validation/min-length? title 3)
                   [:title "Your title must have more than 3 characters"])
  (validation/rule (validation/max-length? title 128)
                   [:title "Your title must have less than 128 characters"])
  (not (validation/errors? :title)))
```

check for validation before adding, display the add form again on fail

```
(defpage [:post "/add"] {:as book}
  (if (valid? book)
    (do
      (session/put! "books" (conj (session/get "books" []) (:title book)))
      (response/redirect "/"))
    (render "/add" book)))
```

### display validation errors

change `(defpage "/add"`

```
(defpage "/add" {:as book}
  (common/layout
   "Add a book"
   [:div.row
    [:div.span3
     [:form {:method "POST"}
      [:fieldset
       {:class (if (validation/errors? :title)
                 "control-group error"
                 "control-group")}
       [:label {:for "title"} "Title"]
       [:input {:type "text"
                :name "title"
                :placeholder "Book title..."}]
       [:p.help-block (first (validation/get-errors :title))]]
      [:button.btn {:type "submit"} "Add"]]]]))
```

## deploy to heroku

create Heroku stack

```
gem install heroku
heroku create
```

create `./Procfile`

```
web: lein run
```

and add the following to your `project.clj`

```
:min-lein-version "2.0.0-preview7"
```

## things you can do next

* move book repository to a PostgreSQL database
* implement deleting books
* add additional book metadata
* search Amazon API or Google Books API by ISBN for book metadata
