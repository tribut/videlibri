package de.benibela.internettools;

import android.util.Log;

import java.security.KeyStore;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Set;

import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;


/**
 * Based on http://download.oracle.com/javase/1.5.0/docs/guide/security/jsse/JSSERefGuide.html#X509TrustManager
 */
public class X509TrustManagerWithAdditionalKeystores extends X509TrustManagerWrapper {

    public interface LazyLoadKeyStoreFactory{
        LazyLoadKeystore factor();
    }

    private LazyLoadKeystore pendingKeystores;
    public static LazyLoadKeyStoreFactory defaultKeystoreFactory;

    public X509TrustManagerWithAdditionalKeystores() {
        super();
        if (defaultKeystoreFactory != null)
            pendingKeystores = defaultKeystoreFactory.factor();
    }
    public X509TrustManagerWithAdditionalKeystores(LazyLoadKeystore additionalkeyStores) {
        super();
        this.pendingKeystores = additionalkeyStores;
    }

    private void loadPendingKeystore(){
        loadKeystore(pendingKeystores.getStore());
        pendingKeystores = null;
    }


    @Override
    public boolean isCheckClientTrusted(X509Certificate[] chain, String authType) {
        if (super.isCheckClientTrusted(chain, authType))
            return true;
        if (pendingKeystores != null) {
            loadPendingKeystore();
            return isCheckClientTrusted(chain, authType);
        }
        return false;
    }


    public boolean isCheckServerTrusted(X509Certificate[] chain, String authType) {
        if (super.isCheckServerTrusted(chain, authType))
            return true;

        //only load additional keystores when the system ones failed
        if (pendingKeystores != null) {
            loadPendingKeystore();
            return isCheckServerTrusted(chain, authType);
        }

        return false;
    }
}
