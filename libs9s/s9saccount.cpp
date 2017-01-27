/*
 * Severalnines Tools
 * Copyright (C) 2016  Severalnines AB
 *
 * This file is part of s9s-tools.
 *
 * s9s-tools is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * S9sTools is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with S9sTools. If not, see <http://www.gnu.org/licenses/>.
 */
#include "s9saccount.h"

#include <S9sVariantMap>

#define DEBUG
//#define WARNING
#include "s9sdebug.h"

S9sAccount::S9sAccount()
{
}
 
S9sAccount::S9sAccount(
        const S9sVariantMap &properties) :
    m_properties(properties)
{
}

/**
 * \param stringRep The string representation of the host, either a JSon string
 *   or an url (e.g. "192.168.1.100:3306".
 */
S9sAccount::S9sAccount(
        const S9sString &stringRep)
{
}

S9sAccount::~S9sAccount()
{
}

S9sAccount &
S9sAccount::operator=(
        const S9sVariantMap &rhs)
{
    setProperties(rhs);
    
    return *this;
}

/**
 * \returns the username (or login-name) for the account.
 */
S9sString
S9sAccount::userName() const
{
    if (m_properties.contains("user_name"))
        return m_properties.at("user_name").toString();

    return S9sString();
}

/**
 * \param value The new username (or 
 * Sets the username for the account.
 */
void
S9sAccount::setUserName(
        const S9sString    &value)
{
    m_properties["user_name"] = value;
}

/**
 * \returns the allowed client host name of the user.
 */
S9sString
S9sAccount::hostAllow() const
{
    if (m_properties.contains("host_allow"))
        return m_properties.at("host_allow").toString();

    return S9sString();
}

/**
 * \param value The host name from where the login is allowed.
 */
void
S9sAccount::setHostAllow(
        const S9sString    &value)
{
    m_properties["host_allow"] = value;
}

const S9sVariantMap &
S9sAccount::toVariantMap() const
{
    return m_properties;
}

void
S9sAccount::setProperties(
        const S9sVariantMap &properties)
{
    m_properties = properties;
}

enum ParseState
{
    StartState,
    UserName,
    SingleQuoteUserName,
    UserNameEnd,
    HostName,
    HostNameStart,
    SingleQuoteHostName,
};

bool 
S9sAccount::parseStringRep(
        const S9sString &input)
{
    int        c;
    ParseState state = StartState;
    S9sString  userName, hostName;

    S9S_DEBUG("*** input: %s", STR(input));
    for (int n = 0;;)
    {
        c = input.c_str()[n];
        S9S_DEBUG("*** n = %02d c = '%c'", n, c);
        
        switch (state)
        {
            case StartState:
                if (c == '\'')
                {
                    ++n;
                    state = SingleQuoteUserName;
                } else {
                    state = UserName;
                }
                break;

            case UserName:
                if (c == '\0')
                {
                    S9S_DEBUG("userName : %s", STR(userName));
                    setUserName(userName);
                    return true;
                } else if (c == '@')
                {
                    n++;
                    state = HostNameStart;
                } else {
                    userName += c;
                    n++;
                }
                break;

            case HostNameStart:
                if (c == '\'')
                {
                    state = SingleQuoteHostName;
                    ++n;
                } else {
                    state = HostName;
                }
                break;

            case HostName:
                if (c == '\0')
                {
                    S9S_DEBUG("userName : %s", STR(userName));
                    setUserName(userName);
                    setHostAllow(hostName);
                    return true;
                } else {
                    hostName += c;
                    ++n;
                }
                break;

            case SingleQuoteUserName:
                if (c == '\0')
                {
                    S9S_WARNING("Single quote (') expected.");
                    return false;
                } else if (c == '\'')
                {
                    setUserName(userName);
                    n++;
                    state = UserNameEnd;
                } else {
                    userName += c;
                    n++;
                }
                break;
            
            case UserNameEnd:
                if (c == '\0')
                {
                    return true;
                } else if (c == '@')
                {
                    n++;
                    state = HostNameStart;
                }
                break;

            case SingleQuoteHostName:
                if (c == '\0')
                {
                    S9S_WARNING("Single quote (') expected.");
                    return false;
                } else if (c == '\'')
                {
                    setUserName(userName);
                    setHostAllow(hostName);
                    return true;
                } else {
                    hostName += c;
                    n++;
                }
                break;
        }
    }

    return false;
}
