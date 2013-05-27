package de.benibela.videlibri;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.app.Activity;
import android.os.Bundle;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.TextView;

import com.actionbarsherlock.app.*;
import com.actionbarsherlock.view.Menu;
import com.actionbarsherlock.view.MenuItem;
import com.actionbarsherlock.view.MenuInflater;

public class VideLibriBaseActivity extends SherlockActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);    //To change body of overridden methods use File | Settings | File Templates.
        getSupportActionBar().setHomeButtonEnabled(true);

    }

    @Override
    protected void onPostCreate(Bundle savedInstanceState) {
        super.onPostCreate(savedInstanceState);    //To change body of overridden methods use File | Settings | File Templates.
    }

    MenuItem loadingItem = null;
    boolean loading = false;

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getSupportMenuInflater();
        inflater.inflate(R.menu.videlibrimenu, menu);
        loadingItem = menu.findItem(R.id.loading);

        View refreshView;
        LayoutInflater linflater = (LayoutInflater)getSupportActionBar().getThemedContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        refreshView = linflater.inflate(R.layout.actionbar_loading, null);;
        loadingItem.setActionView(refreshView);
        loadingItem.setVisible(loading);


        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        boolean x = super.onPrepareOptionsMenu(menu);    //To change body of overridden methods use File | Settings | File Templates.
        if (VideLibri.instance != null) {
            menu.findItem(R.id.refresh).setEnabled(!VideLibri.instance.loading);

            menu.findItem(R.id.accounts).setEnabled(VideLibri.instance.accounts.length > 0);
            menu.findItem(R.id.refresh).setEnabled(VideLibri.instance.accounts.length > 0);
            menu.findItem(R.id.renew).setEnabled(VideLibri.instance.accounts.length > 0);
            menu.findItem(R.id.options).setEnabled(VideLibri.instance.accounts.length > 0);
        }
        return x;
    }

    @Override
    protected void onResume() {
        super.onResume();    //To change body of overridden methods use File | Settings | File Templates.


        /*if(refreshing)
            refreshView = inflater.inflate(R.layout.actionbar_refresh_progress, null);
        else
           refreshView = inflater.inflate(R.layout.actionbar_refresh_button, null);*/


    }

    private static final int REQUESTED_LIBRARY_HOMEPAGE  = 89324;
    private static final int REQUESTED_LIBRARY_CATALOGUE = 89325;

    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle item selection
        Intent intent;
        switch (item.getItemId()) {
            case R.id.search:
                VideLibri.newSearchActivity();
                return true;
            case R.id.accounts:
                intent = new Intent(this, VideLibri.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                startActivity(intent);
                return true;
            case R.id.options:
                intent = new Intent(this, Options.class);
                startActivity(intent);
                return true;
            case R.id.refresh:
                if (VideLibri.instance != null && !VideLibri.instance.loading)
                    VideLibri.updateAccount(null, false, false);
                return true;
            case R.id.renew:
                if (VideLibri.instance != null && !VideLibri.instance.loading)
                    VideLibri.updateAccount(null, false, true);
                return true;
            case R.id.libinfo:
                intent = new Intent(this, LibraryList.class);
                intent.putExtra("reason", "Wählen Sie eine Bücherei um ihre Homepage zu öffnen:");
                intent.putExtra("search", true);
                startActivityForResult(intent, REQUESTED_LIBRARY_HOMEPAGE);
                return true;
            case R.id.libcatalogue:
                intent = new Intent(this, LibraryList.class);
                intent.putExtra("reason", "Wählen Sie eine Bücherei um ihren Webkatalog zu öffnen:");
                intent.putExtra("search", true);
                startActivityForResult(intent, REQUESTED_LIBRARY_CATALOGUE);
                return true;
            case  android.R.id.home:
                openOptionsMenu();
                return true;
        }
        return super.onOptionsItemSelected(item);
    }



    void setLoading(boolean loading){
        this.loading = loading;
        if (loadingItem == null) return;
        loadingItem.setVisible(loading);
    }

    /*@Override
    public void setTitle(CharSequence title){
        super.setTitle(title.length() > 0 ? "VideLibri: "+title : "VideLibri");
    } */

    //Util
    String getStringExtraSafe(String id){
        String r = getIntent().getStringExtra(id);
        if (r == null) return "";
        return  r;
    }

    public Button findButtonById(int id){
        return (Button)findViewById(id);
    }



    public void setTextViewText(int id, CharSequence text){
        TextView tv = (TextView) findViewById(id);
        tv.setText(text);
    }

    public String getTextViewText(int id){
        TextView tv = (TextView) findViewById(id);
        return tv.getText().toString();
    }

    public void setEditTextText(int id, CharSequence text){
        EditText tv = (EditText) findViewById(id);
        tv.setText(text);
    }

    public String getEditTextText(int id){
        EditText tv = (EditText) findViewById(id);
        return tv.getText().toString();
    }

    public void setCheckBoxChecked(int id, boolean text){
        CheckBox tv = (CheckBox) findViewById(id);
        tv.setChecked(text);
    }

    public boolean getCheckBoxChecked(int id){
        CheckBox tv = (CheckBox) findViewById(id);
        return tv.isChecked();
    }


    static interface MessageHandler{
        void onDialogEnd(DialogInterface dialogInterface, int i);
    }
    static int MessageHandlerCanceled = -123;


    public void showMessage(String message){ showMessage(this, message, null); }
    public void showMessage(String message, MessageHandler handler){ showMessage(this, message, handler); }
    public void showMessageYesNo(String message, MessageHandler handler){ showMessage(this, message, "Nein", null, "Ja", handler); }
    static public void showMessage(Context context, String message, final MessageHandler handler){showMessage(context, message, null, "OK", null, handler);}
    static public void showMessage(Context context, String message, String negative, String neutral, String positive, final MessageHandler handler){
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setMessage(message);
        builder.setTitle("VideLibri");
        if (negative != null)
            builder.setNegativeButton(negative, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialogInterface, int i) {
                 if (handler != null) handler.onDialogEnd(dialogInterface, i);
                }
            });
        if (neutral != null)
            builder.setNeutralButton(neutral, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialogInterface, int i) {
                    if (handler != null) handler.onDialogEnd(dialogInterface, i);
                }
            });
        if (positive != null)
            builder.setPositiveButton(positive, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialogInterface, int i) {
                    if (handler != null) handler.onDialogEnd(dialogInterface, i);
                }
            });
        if (handler != null) {
            builder.setOnCancelListener(new DialogInterface.OnCancelListener() {
                @Override
                public void onCancel(DialogInterface dialogInterface) {
                    handler.onDialogEnd(dialogInterface, MessageHandlerCanceled);
                }
            });
        }
        builder.show();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if ((requestCode == REQUESTED_LIBRARY_CATALOGUE || requestCode == REQUESTED_LIBRARY_HOMEPAGE) && resultCode == LibraryList.RESULT_OK) {
            String id = data.getStringExtra("libId");
            String [] details = Bridge.VLGetLibraryDetails(id);
            startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(details[
                requestCode == REQUESTED_LIBRARY_HOMEPAGE ? 0 : 1
            ])));
        }
        else super.onActivityResult(requestCode, resultCode, data);

    }
}
