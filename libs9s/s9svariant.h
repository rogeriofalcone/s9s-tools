/* 
 * Copyright (C) 2011-2015 severalnines.com
 */
#pragma once

#include "s9sunion.h"
#include "S9sString"

class S9sVariant
{
    public:
        inline S9sVariant();
        inline S9sVariant(const int integerValue);
        inline S9sVariant(const ulonglong ullValue);
        inline S9sVariant(double doubleValue);
        inline S9sVariant(const bool boolValue);
        inline S9sVariant(const char *stringValue);
        inline S9sVariant(const std::string &stringValue);
        inline S9sVariant(const S9sString &stringValue);

        virtual ~S9sVariant();

        void clear();

    private:
        S9sBasicType    m_type;
        S9sUnion        m_union;
};

inline 
S9sVariant::S9sVariant() :
    m_type(Invalid)
{
}

inline 
S9sVariant::S9sVariant(
        const int integerValue) :
    m_type(Int)
{
    m_union.iVal = integerValue;
}

inline 
S9sVariant::S9sVariant(
        const ulonglong ullValue) :
    m_type (Ulonglong)
{
    m_union.ullVal = ullValue;
}

inline 
S9sVariant::S9sVariant(
        double doubleValue) :
    m_type (Double)
{
    m_union.dVal = doubleValue;
}

inline 
S9sVariant::S9sVariant(
        const bool boolValue) :
    m_type (Bool)
{
    m_union.bVal = boolValue;
}

inline 
S9sVariant::S9sVariant(
        const char *stringValue) :
    m_type (String)
{
    if (stringValue == NULL)
        m_union.stringValue = new S9sString;
    else
        m_union.stringValue = new S9sString(stringValue);
}

inline 
S9sVariant::S9sVariant(
        const std::string &stringValue) :
    m_type (String)
{
    m_union.stringValue = new S9sString(stringValue);
}

inline 
S9sVariant::S9sVariant(
        const S9sString &stringValue) :
    m_type (String)
{
    m_union.stringValue = new S9sString(stringValue);
}
