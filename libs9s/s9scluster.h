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
 * Foobar is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Foobar. If not, see <http://www.gnu.org/licenses/>.
 */
#pragma once

#include <S9sVariantMap>

class S9sCluster
{
    public:
        S9sCluster();
        S9sCluster(const S9sVariantMap &properties);

        virtual ~S9sCluster();

        S9sCluster &operator=(const S9sVariantMap &rhs);

        const S9sVariantMap &toVariantMap() const;

        S9sString className() const;
        S9sString name() const;
        S9sString ownerName() const;
        S9sString groupOwnerName() const;
        int clusterId() const;

    private:
        S9sVariantMap    m_properties;
};