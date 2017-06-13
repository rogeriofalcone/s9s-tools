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
 * s9s-tools is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with s9s-tools. If not, see <http://www.gnu.org/licenses/>.
 */
#include "s9suser.h"

//#define DEBUG
//#define WARNING
#include "s9sdebug.h"

S9sUser::S9sUser()
{
}
 
S9sUser::S9sUser(
        const S9sVariantMap &properties) :
    m_properties(properties)
{
}

S9sUser::~S9sUser()
{
}

S9sUser &
S9sUser::operator=(
        const S9sVariantMap &rhs)
{
    setProperties(rhs);
    
    return *this;
}

/**
 * \returns The S9sUser converted to a variant map.
 *
\code{.js}
    {
        "class_name": "CmonUser",
        "email_address": "warrior@ds9.com",
        "first_name": "Worf",
        "groups": [ 
        {
            "class_name": "CmonGroup",
            "group_id": 4,
            "group_name": "ds9"
        } ],
        "title": "Lt.",
        "user_id": 12,
        "user_name": "worf"
    }
\endcode
 */
const S9sVariantMap &
S9sUser::toVariantMap() const
{
    return m_properties;
}

/**
 * \returns True if a property with the given key exists.
 */
bool
S9sUser::hasProperty(
        const S9sString &key) const
{
    return m_properties.contains(key);
}

/**
 * \returns The value of the property with the given name or the empty
 *   S9sVariant object if the property is not set.
 */
S9sVariant
S9sUser::property(
        const S9sString &name) const
{
    if (m_properties.contains(name))
        return m_properties.at(name);

    return S9sVariant();
}

/**
 * \param name The name of the property to set.
 * \param value The value of the property as a string.
 *
 * This function will investigate the value represented as a string. If it looks
 * like a boolean value (e.g. "true") then it will be converted to a boolean
 * value, if it looks like an integer (e.g. 42) it will be converted to an
 * integer. Then the property will be set accordingly.
 */
void
S9sUser::setProperty(
        const S9sString &name,
        const S9sString &value)
{
    if (value.looksBoolean())
    {
        m_properties[name] = value.toBoolean();
    } else if (value.looksInteger())
    {
        m_properties[name] = value.toInt();
    } else {
        m_properties[name] = value;
    }
}

/**
 * \param properties The properties to be set as a name -> value mapping.
 *
 * Sets all the properties in one step. All the existing properties will be
 * deleted, then the new properties set.
 */
void
S9sUser::setProperties(
        const S9sVariantMap &properties)
{
    m_properties = properties;
}

/**
 * \returns The username of the user.
 */
S9sString
S9sUser::userName() const
{
    if (m_properties.contains("user_name"))
        return m_properties.at("user_name").toString();

    return S9sString();
}

/**
 * \returns The email address of the user.
 */
S9sString
S9sUser::emailAddress() const
{
    if (m_properties.contains("email_address"))
        return m_properties.at("email_address").toString();

    return S9sString();
}

int
S9sUser::userId() const
{
    if (m_properties.contains("user_id"))
        return m_properties.at("user_id").toInt();

    return 0;
}

S9sString
S9sUser::firstName() const
{
    if (m_properties.contains("first_name"))
        return m_properties.at("first_name").toString();

    return S9sString();
}

S9sString
S9sUser::lastName() const
{
    if (m_properties.contains("last_name"))
        return m_properties.at("last_name").toString();

    return S9sString();
}

S9sString
S9sUser::middleName() const
{
    if (m_properties.contains("middle_name"))
        return m_properties.at("middle_name").toString();

    return S9sString();
}

S9sString
S9sUser::title() const
{
    if (m_properties.contains("title"))
        return m_properties.at("title").toString();

    return S9sString();
}

S9sString
S9sUser::jobTitle() const
{
    if (m_properties.contains("job_title"))
        return m_properties.at("job_title").toString();

    return S9sString();
}

