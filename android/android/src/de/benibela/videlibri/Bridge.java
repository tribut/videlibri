package de.benibela.videlibri;

import android.*;
import android.R;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.util.Log;

import java.io.Serializable;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.Map;
import java.util.TreeMap;

public class Bridge {
    public static class Account implements Serializable{
        String libId, name, pass, prettyName;
        boolean extend;
        int extendDays;
        boolean history;
        public boolean equals(Object o) {
            if (!(o instanceof Account)) return  false;
            Account a = (Account) o;
            return  (a.libId == libId && a.prettyName == prettyName);
        }
        String internalId(){
            return libId+"_"+name;
        }
        Library getLibrary(){ //warning slow
            Library[] libs = getLibraries();
            for (Library lib: libs)
                if (lib.id.equals(libId)) return lib;
            return null;
        }
    }

    public static class Book implements Serializable{
        Account account;
        String author = "";
        String title = "";
        String dueDatePretty = "";
        GregorianCalendar issueDate;
        GregorianCalendar dueDate;
        boolean history;
        Map<String, String> more = new TreeMap<String, String>();

        Bitmap image; //handled on Javasite only

        @Override
        public String toString() {
            return title;
        }

        int getStatusColor(){
            if (dueDate == null) return -1;
            int c = Color.GREEN;
            if (this.history) c = -1;
            else if (this.dueDate.getTimeInMillis() - Calendar.getInstance().getTimeInMillis() < 1000 * 60 * 60 * 24 * 3) c = Color.RED;
            else if ("critical".equals(this.more.get("statusId"))) c = Color.YELLOW;
            else c = Color.GREEN;
            return c;
        }

        //called from Videlibri midend
        void setProperty(String name, String value){
            more.put(name, value);
        }
    }

    public static class InternalError extends Exception {
        public InternalError() {}
        public InternalError(String msg) { super(msg); }
    }

    public static class PendingException{
        String accountPrettyNames, error, details;
    }

    static public native void VLInit(VideLibri videlibri);
    static public native String[] VLGetLibraries(); //id|pretty location|name|short name
    static public native Account[] VLGetAccounts();
    static public native void VLAddAccount(Account acc);
    static public native void VLChangeAccount(Account oldacc, Account newacc);
    static public native void VLDeleteAccount(Account acc);
    static public native Book[] VLGetBooks(Account acc, boolean history);
    static public native void VLUpdateAccount(Account acc, boolean autoUpdate, boolean forceExtend);
    static public native PendingException[] VLTakePendingExceptions();


    static public native void VLSearchStart(SearcherAccess searcher, Book query);
    static public native void VLSearchNextPage(SearcherAccess searcher);
    static public native void VLSearchDetails(SearcherAccess searcher, Book book);
    static public native void VLSearchEnd(SearcherAccess searcher);

    static public native void VLFinalize();


    //SearcherAccess helper class like in Pascal-VideLibri
    //All methods run asynchronously in a Pascal Thread
    //All events are called in the same thread ()
    public static class SearcherAccess implements SearchResultDisplay{
        long nativePtr;
        final SearchResultDisplay display;

        int totalResultCount;
        boolean nextPageAvailable;

        SearcherAccess(SearchResultDisplay display, Book query){
            this.display = display;
            VLSearchStart(this, query);
        }
        public void nextPage(){
            VLSearchNextPage(this);
        }
        public void details(Book book){
            VLSearchDetails(this, book);
        }
        public void free(){
            VLSearchEnd(this);
        }

        public void onSearchFirstPageComplete(Book[] books) { display.onSearchFirstPageComplete(books); }
        public void onSearchNextPageComplete(Book[] books) { display.onSearchNextPageComplete(books); }
        public void onSearchDetailsComplete(Book book) { display.onSearchDetailsComplete(book); }
        public void onException() { display.onException(); }
    }


    public static interface SearchResultDisplay{
        void onSearchFirstPageComplete(Book[] books);
        void onSearchNextPageComplete(Book[] books);
        void onSearchDetailsComplete(Book book);
        void onException();
    }


    static class Library{
        String id, locationPretty, namePretty, nameShort;
        void putInIntent(Intent intent){
            intent.putExtra("libName", namePretty);
            intent.putExtra("libShortName", nameShort);
            intent.putExtra("libId", id);
        }
    }
    static Library[] getLibraries(){
        String libs[] =  VLGetLibraries();
        Library[] result = new Library[libs.length];
        for (int i=0;i<libs.length;i++){
            result[i] = new Library();
            String[] temp = libs[i].split("\\|");
            result[i].id = temp[0];
            result[i].locationPretty = temp[1];
            result[i].namePretty = temp[2];
            result[i].nameShort = temp[3];
        }
        return result;
    }

    //const libID: string; prettyName, aname, pass: string; extendType: TExtendType; extendDays:integer; history: boolean 

    //mock functions

    /*static public Account[] VLGetAccounts(){
        return new Account[0];
    }
    static public void VLAddAccount(Account acc){

    }
    static public void VLChangeAccount(Account oldacc, Account newacc){

    }
    static public void VLDeleteAccount(Account acc){}*/
    //static public Book[] VLGetBooks(Account acc, boolean history){return  new Book[0];}
    //static public void VLUpdateAccount(Account acc){}


    static public void log(final String message){
        Log.i("VideLibri", message);
    }


    static
    {
        try //from LCLActivity
        {
            Log.i("videlibri", "Trying to load liblclapp.so");
            System.loadLibrary("lclapp");
        }
        catch(UnsatisfiedLinkError ule)
        {
            Log.e("videlibri", "WARNING: Could not load liblclapp.so");
            ule.printStackTrace();
        }
    }
}