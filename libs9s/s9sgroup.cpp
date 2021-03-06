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
#include "s9sgroup.h"

//#define DEBUG
//#define WARNING
#include "s9sdebug.h"

S9sGroup::S9sGroup()
{
    m_properties["class_name"] = "CmonGroup";
}

S9sGroup::S9sGroup(
        const S9sVariantMap &properties) :
    m_properties(properties)
{
    m_properties["class_name"] = "CmonGroup";
}

S9sGroup::~S9sGroup()
{
}

S9sGroup &
S9sGroup::operator=(
        const S9sVariantMap &rhs)
{
    setProperties(rhs);
    
    return *this;
}


/**
 * \returns The S9sGroup converted to a variant map.
 *
\code{.js}
    {
        "class_name": "CmonGroup",
        "group_id": 5,
        "group_name": "ds9"
    }
\endcode
 */
const S9sVariantMap &
S9sGroup::toVariantMap() const
{
    return m_properties;
}

/**
 * \returns True if a property with the given key exists.
 */
bool
S9sGroup::hasProperty(
        const S9sString &key) const
{
    return m_properties.contains(key);
}

/**
 * \returns The value of the property with the given name or the empty
 *   S9sVariant object if the property is not set.
 */
S9sVariant
S9sGroup::property(
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
S9sGroup::setProperty(
        const S9sString &name,
        const S9sString &value)
{
    if (value.empty())
    {
        m_properties.erase(name);
        return;
    }

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
S9sGroup::setProperties(
        const S9sVariantMap &properties)
{
    m_properties = properties;
}

/**
 * \returns The groupname of the group.
 */
S9sString
S9sGroup::groupName() const
{
    if (m_properties.contains("group_name"))
        return m_properties.at("group_name").toString();

    return S9sString();
}

/**
 * \returns The unique numerical ID of the group.
 */
int
S9sGroup::groupId() const
{
    if (m_properties.contains("group_id"))
        return m_properties.at("group_id").toInt();

    return 0;
}
