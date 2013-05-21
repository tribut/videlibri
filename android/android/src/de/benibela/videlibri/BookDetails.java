package de.benibela.videlibri;


import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Typeface;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.*;

import java.io.InputStream;
import java.util.*;

public class BookDetails extends VideLibriBaseActivity {
    Bridge.Book book;

    static class Details{
        String name, data;
        Details(String name, String data){
            this.name = name;
            this.data = data;
            if (name == null) this.name = "??";
            if (this.name.endsWith("!")) this.name = this.name.substring(0,this.name.length()-1);
            if (data == null) this.data = "";
        }
    }

    static class BookDetailsAdapter extends BaseAdapter{
        private final Activity context;
        private final ArrayList<Details> details;
        private final Bridge.Book book;


        final int defaultColor;
        final float scale;
        int toPx(float sp) { return (int) (sp * scale + 0.5f); }

        BookDetailsAdapter(Activity context, ArrayList<Details> details, Bridge.Book book){
            super();
            this.context = context;
            this.details = details;
            this.book = book;
            if (book.image != null) image = new BitmapDrawable(book.image);

            this.defaultColor = context.getResources().getColor(android.R.color.primary_text_dark);

            this.scale = context.getResources().getDisplayMetrics().scaledDensity;
        }

        static class ViewHolder {
            public TextView text;
        }

        @Override
        public int getCount() {
            return 2 * details.size() + 1;
        }

        @Override
        public Object getItem(int i) {
            return details.get((i-1)/2);
        }

        @Override
        public long getItemId(int i) {
            return i;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            View view = convertView;
            if (view == null){
                LayoutInflater inflater = context.getLayoutInflater();
                view = inflater.inflate(R.layout.simpletextview, null);
                ViewHolder viewHolder = new ViewHolder();
                viewHolder.text = (TextView) view.findViewById(R.id.simpletextview);
                view.setTag(viewHolder);
            }
            ViewHolder holder = (ViewHolder) view.getTag();
            if (position > 0) {
                Details d = details.get((position-1)/2);
                int c =  defaultColor;
                if (position % 2 == 1) {
                    holder.text.setTypeface(Typeface.DEFAULT_BOLD);
                    holder.text.setText(d.name);
                    holder.text.setPadding(toPx(10),toPx(1),toPx(10),toPx(1));
                } else {
                    holder.text.setTypeface(Typeface.DEFAULT);
                    holder.text.setText(d.data);
                    holder.text.setPadding(toPx(30),toPx(1),toPx(10),toPx(2));
                    if ("Bemerkung".equals(d.name) || "Abgabefrist".equals(d.name)){
                        c = book.getStatusColor();
                        if (c == -1) c = defaultColor;
                    }
                }
                holder.text.setCompoundDrawables(null, null, null, null);
                holder.text.setTextColor(c);
            } else {
                holder.text.setText("");
                holder.text.setCompoundDrawablesWithIntrinsicBounds(null, null, null, image);
            }


            return view;
        }

        Drawable image;
        void updateImage(){
            image = new BitmapDrawable(book.image);
            notifyDataSetChanged();
        }
    }

    ArrayList<Details> details = new ArrayList<Details>();
    void addIfExists(String displayName, String propertyName){
        String value = book.more.get(propertyName);
        if (value == null || "".equals(value)) return;
        details.add(new Details(displayName, value));
    }

    static BookDetails instance = null;

    static Bridge.Book bookToView = null; //passed as parameter to newly created detail display (do not serialize, as it crashes with books with images and is slow in any case)

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.bookdetails);

        setBook( bookToView );
        bookToView = null;
    }

    @Override
    protected void onResume() {
        super.onResume();    //To change body of overridden methods use File | Settings | File Templates.
        instance = this;
    }

    @Override
    protected void onPause() {
        instance = null;
        super.onPause();    //To change body of overridden methods use File | Settings | File Templates.
    }

    void setBook(Bridge.Book newBook){
        book = newBook;
        if (book == null) book = new Bridge.Book();

        boolean searchedBook = book.account == null;

        ListView lv = (ListView) findViewById(R.id.bookdetailsview);


        details.clear();
        details.add(new Details("Titel", book.title));
        details.add(new Details("Verfasser", book.author));
        if ((!searchedBook && !book.history) || book.dueDate != null)
            details.add(new Details("Abgabefrist", book.dueDatePretty));

        String status = book.more.get("status");
        if (status == null) status = "";
        if ("".equals(status) && "critical".equals(book.more.get("statusId"))) status = "(nicht verlängerbar)";
        if (!"".equals(status)) details.add(new Details("Bemerkung", status));

        if (book.issueDate != null)
          details.add(new Details("Ausleihdatum", android.text.format.DateFormat.getDateFormat(this).format(book.issueDate.getTime())));
        addIfExists("Ausgeliehen in", "libraryBranch");
        if (book.account != null) details.add(new Details("Konto", book.account.prettyName));

        addIfExists("ID", "id");
        addIfExists("Kategorie", "category");
        addIfExists("Jahr", "year");
        addIfExists("Verlag", "publisher");

        final List<String> above = Arrays.asList("status", "id", "category", "year", "statusId", "libraryBranch", "publisher");

        for (Map.Entry<String, String> entry : book.more.entrySet())
            if ( entry.getValue() != null && !"".equals(entry.getValue()) && (
                    (!searchedBook && !above.contains(entry.getKey()))
                    || (searchedBook && entry.getKey().endsWith("!"))
            ))
                details.add(new Details(entry.getKey(), entry.getValue()));

        lv.setAdapter(new BookDetailsAdapter(this, details, book));

        setLoading(searchedBook && (!book.more.containsKey("__details") || (book.image == null && book.more.containsKey("image-url"))));

        if (book.more != null && book.more.containsKey("image-url") && book.image == null)
            new DownloadImageTask(this, book).execute(book.more.get("image-url"));

    }

    void updateImage(){
        setLoading(false);
        ((BookDetailsAdapter) (((ListView) findViewById(R.id.bookdetailsview)).getAdapter())).updateImage();
    }

    //from http://stackoverflow.com/questions/5776851/load-image-from-url
    class DownloadImageTask extends AsyncTask<String, Void, Bitmap> {
        ImageView bmImage;
        Bridge.Book book;
        BookDetails activity;

        public DownloadImageTask(BookDetails activity, Bridge.Book book) {
            this.book = book;
            this.bmImage = bmImage;
            this.activity = activity;
        }

        protected Bitmap doInBackground(String... urls) {
            String urldisplay = urls[0];
            Bitmap mIcon11 = null;
            try {
                InputStream in = new java.net.URL(urldisplay).openStream();
                mIcon11 = BitmapFactory.decodeStream(in);
            } catch (Exception e) {
                //Log.e("Error", e.getMessage());
                e.printStackTrace();
            }
            return mIcon11;
        }

        protected void onPostExecute(Bitmap result) {
            book.image = result;
            if (book == activity.book) activity.updateImage();
        }
    }
}
