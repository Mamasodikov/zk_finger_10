package com.mamasodikov.zkfinger10.util;

public class FingerStatus {
    String message;
    FingerStatusType fingerStatusType;
    String id;
    String data;

    public FingerStatus(String message, FingerStatusType fingerStatusType, String id, String data) {
        this.message = message;
        this.fingerStatusType = fingerStatusType;
        this.id = id;
        this.data = data;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public FingerStatusType getFingerStatusType() {
        return fingerStatusType;
    }

    public void setFingerStatusType(FingerStatusType fingerStatusType) {
        this.fingerStatusType = fingerStatusType;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getData() {
        return data;
    }

    public void setData(String data) {
        this.data = data;
    }
}