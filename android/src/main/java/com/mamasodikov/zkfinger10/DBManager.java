package com.mamasodikov.zkfinger10;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import java.util.HashMap;

public class DBManager {
    private String dbName;
    SQLiteDatabase db = null;
    boolean bIsOpened = false;
    public boolean opendb(String fileName)
    {
        if (bIsOpened)
        {
            return true;
        }
        dbName = fileName;
        db = SQLiteDatabase.openOrCreateDatabase(dbName, null);
        if (null == db)
        {
            return false;
        }
        String strSQL = "create table if not exists userinfo(id integer primary key autoincrement,pin text not null,feature text not null)";
        db.execSQL(strSQL);
        bIsOpened = true;
        return true;
    }

    public boolean isUserExisted(String pin)
    {
        if (!bIsOpened)
        {
            opendb(dbName);
        }
        if (null == db)
        {
            return false;
        }
        Cursor cursor = db.query("userinfo", null, "pin=?", new String[] { pin }, null, null, null);
        boolean exists = cursor.getCount() > 0;
        cursor.close();
        return exists;
    }

    public boolean deleteUser(String pin)
    {
        if (!bIsOpened)
        {
            opendb(dbName);
        }
        if (null == db)
        {
            return false;
        }
        db.delete("userinfo", "pin=?", new String[] { pin });
        return true;
    }


    public boolean clear()
    {
        if (!bIsOpened)
        {
            opendb(dbName);
        }
        if (null == db)
        {
            return false;
        }
        String strSQL = "delete from userinfo;";
        db.execSQL(strSQL);
        return true;
    }

    public boolean modifyUser(String pin, String feature)
    {
        if (!bIsOpened)
        {
            opendb(dbName);
        }
        if (null == db)
        {
            return false;
        }
        ContentValues value = new ContentValues();
        value.put("feature", feature);
        db.update("userinfo", value, "pin=?", new String[] { pin });
        return true;
    }

    public int getCount()
    {
        if (!bIsOpened)
        {
            opendb(dbName);
        }
        if (null == db)
        {
            return 0;
        }
        Cursor cursor = db.query("userinfo", null, null, null, null, null, null);
        int count = cursor.getCount();
        cursor.close();
        return count;
    }

    public boolean insertUser(String pin, String feature)
    {
        if (!bIsOpened)
        {
            opendb(dbName);
        }
        if (null == db)
        {
            return false;
        }
        ContentValues value = new ContentValues();
        value.put("pin", pin);
        value.put("feature", feature);
        db.insert("userinfo", null, value);
        return true;
    }

    public HashMap<String, String> queryUserList()
    {
        if (!bIsOpened)
        {
            return null;
        }
        if (null == db)
        {
            return null;
        }
        Cursor cursor = db.query("userinfo", null, null, null, null, null, null);
        if (cursor.getCount() == 0)
        {
            cursor.close();
            return null;
        }
        HashMap<String, String> map = new HashMap<String, String>();
        for (cursor.moveToFirst();!cursor.isAfterLast();cursor.moveToNext()) {
           map.put(cursor.getString(cursor.getColumnIndexOrThrow("pin")), cursor.getString(cursor.getColumnIndexOrThrow("feature")));
        }
        cursor.close();
        return map;
    }

    public String getUserFeature(String pin) {
        if (!bIsOpened) {
            opendb(dbName);
        }
        if (null == db) {
            return null;
        }
        Cursor cursor = db.query("userinfo", new String[]{"feature"}, "pin=?", new String[] { pin }, null, null, null);
        if (cursor.getCount() == 0) {
            cursor.close();
            return null;
        }
        cursor.moveToFirst();
        String feature = cursor.getString(cursor.getColumnIndexOrThrow("feature"));
        cursor.close();
        return feature;
    }

    public boolean updateUserFeature(String pin, String feature) {
        if (!bIsOpened) {
            opendb(dbName);
        }
        if (null == db) {
            return false;
        }
        ContentValues value = new ContentValues();
        value.put("feature", feature);
        int rowsAffected = db.update("userinfo", value, "pin=?", new String[] { pin });
        return rowsAffected > 0;
    }

    public void closeDatabase() {
        if (db != null && bIsOpened) {
            db.close();
            bIsOpened = false;
        }
    }

}
