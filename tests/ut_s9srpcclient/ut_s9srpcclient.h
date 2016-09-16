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
#include "s9sunittest.h"

#include <S9sRpcClient>

class UtS9sRpcClient : public S9sUnitTest
{
    public:
        UtS9sRpcClient();
        virtual ~UtS9sRpcClient();
        virtual bool runTest(const char *testName = 0);
    
    protected:
        bool testGetAllClusterInfo();
        bool testSetHost();
        bool testCreateGalera();
        bool testCreateReplication();
};

class S9sRpcClientTester : public S9sRpcClient
{
    public:
        S9sString uri(const uint index) const;
        S9sString payload(const uint index) const;

    protected:
        virtual bool 
            executeRequest(
                const S9sString &uri,
                const S9sString &payload);

    private:
        S9sVariantList    m_urls;
        S9sVariantList    m_payloads;
};

